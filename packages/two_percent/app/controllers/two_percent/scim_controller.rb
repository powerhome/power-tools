# frozen_string_literal: true

module TwoPercent
  class ScimController < ApplicationController
    def create
      record = with_scim_logging("create") do
        # Persist to two_percent tables first (validates SCIM schema)
        record = persist_scim_record(scim_params)

        # Reload with associations for domain event and response
        record = reload_with_members(record)

        # Publish domain event (not SCIM-specific)
        publish_created_event(record)

        record
      end

      # RFC 7644: 201 Created with Location header and resource body
      render json: record.to_scim_representation, status: :created, location: scim_resource_url(record)
    end

    def update
      record = with_scim_logging("update") do
        # Find existing record
        record = find_scim_record(params[:id])

        # Validate RFC 7643 read-only attributes before processing
        validate_patch_operations!(scim_params) if user_resource?

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

        updated_record
      end

      # RFC 7644: 200 OK with updated resource body
      render json: record.to_scim_representation, status: :ok
    end

    def replace
      # Upsert record (create or replace)
      was_new = !model_class.exists_by_scim_id?(params[:id])

      record = with_scim_logging("replace") do
        record = upsert_scim_record(params[:id], scim_params)

        # Reload with associations for domain event and response
        record = reload_with_members(record)

        # Publish appropriate domain event
        if was_new
          publish_created_event(record)
        else
          publish_updated_event(record)
        end

        record
      end

      # RFC 7644: 201 Created (if new) or 200 OK (if replaced)
      if was_new
        render json: record.to_scim_representation, status: :created, location: scim_resource_url(record)
      else
        render json: record.to_scim_representation, status: :ok
      end
    end

    def destroy
      scim_id = with_scim_logging("delete") do
        # Find and destroy record
        record = find_scim_record(params[:id])
        scim_id = record.scim_id

        # Destroy record
        model_class.destroy_by_scim_id(scim_id)

        # Publish domain delete event
        publish_deleted_event(scim_id)

        scim_id
      end

      # RFC 7644: 204 No Content
      head :no_content
    end

    def show
      validate_resource_type!

      record = with_scim_logging("get") do
        # Find record (raises RecordNotFound if not exists)
        record = find_scim_record(params[:id])

        # Reload with associations for complete SCIM representation
        reload_with_members(record)
      end

      # RFC 7644: 200 OK with resource body (no domain events for read operations)
      render json: record.to_scim_representation, status: :ok
    end

    def index
      validate_resource_type!
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
      TwoPercent.config.group_resource_types.include?(params[:resource_type])
    end

    def validate_resource_type!
      return if user_resource? || group_resource?

      raise ArgumentError, "Unknown resource type: #{params[:resource_type]}"
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
      record = model_class.find_by_scim_id(scim_id)
      raise ActiveRecord::RecordNotFound, "Resource \"#{scim_id}\" not found" unless record

      record
    end

    def upsert_scim_record(scim_id, scim_hash)
      # Ensure scim_id is in the hash
      scim_hash_with_id = scim_hash.merge("id" => scim_id)
      persist_scim_record(scim_hash_with_id)
    end

    def with_scim_logging(operation)
      log_scim_operation(operation, "start", params[:id])
      record = yield
      scim_id = record.respond_to?(:scim_id) ? record.scim_id : record
      log_scim_operation(operation, "complete", scim_id || params[:id])
      record
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
      model_class.includes(association_name).find(record.id)
    end

    # Build base query scope with optional filtering
    def build_query_scope
      base_scope = user_resource? ? model_class.all : model_class.where(resource_type: params[:resource_type])

      # Apply query filtering if present
      scope = if params[:query].present?
                # Sanitize LIKE wildcards (%, _, \) before interpolating into pattern
                sanitized_query = ActiveRecord::Base.sanitize_sql_like(params[:query])
                base_scope.where("LOWER(display_name) LIKE LOWER(?) ESCAPE '\\'", "%#{sanitized_query}%")
              else
                base_scope
              end

      # Order by id for deterministic pagination results
      # Without ORDER BY, paginated results are non-deterministic and can return duplicates/skip records
      scope.order(:id)
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
      scope.includes(association_name).to_a
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

    def model_class
      user_resource? ? TwoPercent::ScimUser : TwoPercent::ScimGroup
    end

    def association_name
      user_resource? ? :scim_groups : :scim_users
    end

    # Validate PATCH operations against RFC 7643 read-only attributes
    # @raise [TwoPercent::ReadOnlyAttributeError] if attempting to modify read-only User.groups
    def validate_patch_operations!(patch_request)
      operations = patch_request["Operations"] || patch_request[:Operations]
      return unless operations.is_a?(Array)

      operations.each do |operation|
        path = operation["path"] || operation[:path]
        next unless path

        # Extract base attribute from path (e.g., "groups" from "groups[value eq '123']")
        base_path = path.split(/[.\[]/).first

        next unless base_path == "groups"

        # RFC 7643 Section 4.1.2: User.groups is read-only
        # RFC 7644 Section 3.5.2: Return 400 with scimType="mutability"
        raise TwoPercent::ReadOnlyAttributeError,
              "Attribute 'groups' is read-only per SCIM RFC 7643. Manage group membership via PATCH /scim/Groups/{id}"
      end
    end
  end
end
