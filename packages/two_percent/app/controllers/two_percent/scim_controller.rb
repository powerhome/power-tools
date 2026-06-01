# frozen_string_literal: true

module TwoPercent
  class ScimController < ApplicationController
    def create
      log_scim_operation("create", "start")

      # Persist to two_percent tables first (validates SCIM schema)
      record = persist_scim_record(scim_params)

      # Reload with associations for domain event and response
      record = reload_with_members(record)

      # Publish domain event (not SCIM-specific)
      publish_created_event(record)

      log_scim_operation("create", "complete", record.scim_id)

      # RFC 7644: 201 Created with Location header and resource body
      response.headers["Location"] = scim_resource_url(record)
      render json: record.to_scim_representation, status: :created
    end

    def update
      log_scim_operation("update", "start")

      # Find existing record
      record = find_scim_record(params[:id])

      # Apply SCIM PATCH operations (RFC 7644 compliance)
      processor = TwoPercent::Scim::PatchProcessor.new(scim_params)
      current_scim_data = record.scim_data || {}
      patched_data = processor.apply_to_hash(current_scim_data)

      # Persist patched data
      patched_data["id"] = params[:id] # Ensure ID is present
      updated_record = persist_scim_record(patched_data)

      # Reload with associations for domain event and response
      updated_record = reload_with_members(updated_record)

      # Publish domain event with final state
      publish_updated_event(updated_record)

      log_scim_operation("update", "complete", record.scim_id)

      # RFC 7644: 200 OK with updated resource body
      render json: updated_record.to_scim_representation, status: :ok
    end

    def replace
      log_scim_operation("replace", "start")

      # Upsert record (create or replace)
      was_new =
        if user_resource?
          !TwoPercent::ScimUser.exists_by_scim_id?(params[:id])
        else
          !TwoPercent::ScimGroup.exists_by_scim_id?(params[:id])
        end

      record = upsert_scim_record(params[:id], scim_params)

      # Reload with associations for domain event and response
      record = reload_with_members(record)

      # Publish appropriate domain event
      if was_new
        publish_created_event(record)
      else
        publish_updated_event(record)
      end

      log_scim_operation("replace", "complete", record.scim_id)

      # RFC 7644: 201 Created (if new) or 200 OK (if replaced)
      if was_new
        response.headers["Location"] = scim_resource_url(record)
        render json: record.to_scim_representation, status: :created
      else
        render json: record.to_scim_representation, status: :ok
      end
    end

    def destroy
      log_scim_operation("delete", "start")

      # Find and destroy record
      record = find_scim_record(params[:id])
      scim_id = record.scim_id

      # Destroy record
      if user_resource?
        TwoPercent::ScimUser.destroy_by_scim_id(scim_id)
      else
        TwoPercent::ScimGroup.destroy_by_scim_id(scim_id)
      end

      # Publish domain delete event
      publish_deleted_event(scim_id)

      log_scim_operation("delete", "complete", scim_id)

      # RFC 7644: 204 No Content
      head :no_content
    end

    def show
      log_scim_operation("get", "start", params[:id])

      # Find record (raises RecordNotFound if not exists)
      record = find_scim_record(params[:id])

      # Reload with associations for complete SCIM representation
      record = reload_with_members(record)

      log_scim_operation("get", "complete", record.scim_id)

      # RFC 7644: 200 OK with resource body (no domain events for read operations)
      render json: record.to_scim_representation, status: :ok
    end

    def index
      log_scim_operation("list", "start")

      # Build base query scope
      scope = build_query_scope

      # Get total count before pagination
      total_count = scope.count

      # Apply pagination
      paginated_scope = apply_pagination(scope)

      # Load records with associations
      records = load_records_with_associations(paginated_scope)

      # Build RFC 7644 ListResponse
      list_response = build_list_response(records, total_count)

      log_scim_operation("list", "complete")

      # RFC 7644: 200 OK with ListResponse (no domain events for read operations)
      render json: list_response, status: :ok
    end

  private

    def scim_params
      params.except(:controller, :action, :resource_type).as_json.with_indifferent_access
    end

    def user_resource?
      params[:resource_type] == "Users"
    end

    def group_resource?
      %w[Groups Departments Territories Roles Titles].include?(params[:resource_type])
    end

    def persist_scim_record(scim_hash)
      if user_resource?
        TwoPercent::ScimUser.upsert_from_scim(scim_hash, correlation_id: @correlation_id)
      elsif group_resource?
        TwoPercent::ScimGroup.upsert_from_scim(params[:resource_type], scim_hash, correlation_id: @correlation_id)
      else
        raise ArgumentError, "Unknown resource type: #{params[:resource_type]}"
      end
    end

    def find_scim_record(scim_id)
      record =
        if user_resource?
          TwoPercent::ScimUser.find_by_scim_id(scim_id)
        elsif group_resource?
          TwoPercent::ScimGroup.find_by_scim_id(scim_id)
        else
          raise ArgumentError, "Unknown resource type: #{params[:resource_type]}"
        end

      raise ActiveRecord::RecordNotFound, "Resource \"#{scim_id}\" not found" unless record

      record
    end

    def upsert_scim_record(scim_id, scim_hash)
      # Ensure scim_id is in the hash
      scim_hash_with_id = scim_hash.merge("id" => scim_id)
      persist_scim_record(scim_hash_with_id)
    end

    def log_scim_operation(operation, stage, scim_id = nil)
      log_data = {
        correlation_id: @correlation_id,
        operation: operation,
        resource_type: params[:resource_type],
        stage: stage,
        service: "two_percent",
      }
      log_data[:scim_id] = scim_id if scim_id

      Rails.logger.info(log_data.to_json)
    end

    # Domain event publishers
    def publish_created_event(record)
      if user_resource?
        TwoPercent::Domain::Events::UserCreated.create(
          user_attributes: record.to_domain_attributes,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupCreated.create(
          group_attributes: record.to_domain_attributes,
          resource_type: params[:resource_type],
          correlation_id: @correlation_id
        )
      end
    end

    def publish_updated_event(record)
      if user_resource?
        TwoPercent::Domain::Events::UserUpdated.create(
          user_attributes: record.to_domain_attributes,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupUpdated.create(
          group_attributes: record.to_domain_attributes,
          resource_type: params[:resource_type],
          correlation_id: @correlation_id
        )
      end
    end

    def publish_deleted_event(scim_id)
      if user_resource?
        TwoPercent::Domain::Events::UserDeleted.create(
          user_id: scim_id,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupDeleted.create(
          group_id: scim_id,
          resource_type: params[:resource_type],
          correlation_id: @correlation_id
        )
      end
    end

    # Generate SCIM resource URL for Location header (RFC 7644)
    def scim_resource_url(record)
      resource_type = user_resource? ? "Users" : params[:resource_type]
      "#{request.base_url}/scim/#{resource_type}/#{record.scim_id}"
    end

    # Reload record with associations (users load groups, groups load members)
    def reload_with_members(record)
      if user_resource?
        TwoPercent::ScimUser.includes(:scim_groups).find(record.id)
      else
        TwoPercent::ScimGroup.includes(:scim_users).find(record.id)
      end
    end

    # Index action helpers

    # Build base query scope with optional filtering
    def build_query_scope
      base_scope = user_resource? ? TwoPercent::ScimUser.all : TwoPercent::ScimGroup.where(resource_type: params[:resource_type])

      return base_scope unless params[:query].present?

      # Apply query filter (display_name substring match, case-insensitive)
      base_scope.where("LOWER(display_name) LIKE LOWER(?)", "%#{params[:query]}%")
    end

    # Apply SCIM pagination (RFC 7644 uses 1-based indexing)
    def apply_pagination(scope)
      start_index = (params[:startIndex] || 1).to_i
      count = (params[:count] || 100).to_i

      # Enforce maximum count limit
      count = [count, 1000].min

      # Convert SCIM 1-based startIndex to 0-based offset
      offset = [start_index - 1, 0].max

      scope.offset(offset).limit(count)
    end

    # Load records with associations
    def load_records_with_associations(scope)
      if user_resource?
        scope.includes(:scim_groups).to_a
      else
        scope.includes(:scim_users).to_a
      end
    end

    # Build RFC 7644 ListResponse format
    def build_list_response(records, total_count)
      start_index = (params[:startIndex] || 1).to_i

      {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
        totalResults: total_count,
        startIndex: start_index,
        itemsPerPage: records.size,
        Resources: records.map(&:to_scim_representation),
      }
    end
  end
end
