# frozen_string_literal: true

module TwoPercent
  class ScimController < ApplicationController
    before_action :extract_correlation_id

    def create
      log_scim_operation("create", "start")

      # Persist to two_percent tables first (validates SCIM schema)
      record = persist_scim_record(scim_params)

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
      patched_data["id"] = params[:id]  # Ensure ID is present
      updated_record = persist_scim_record(patched_data)

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
          !TwoPercent.user_repository.exists_by_scim_id?(params[:id])
        else
          !TwoPercent.group_repository.exists_by_scim_id?(params[:id])
        end
      
      record = upsert_scim_record(params[:id], scim_params)

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
      
      # Destroy using repository method
      if user_resource?
        TwoPercent.user_repository.destroy_by_scim_id(scim_id)
      else
        TwoPercent.group_repository.destroy_by_scim_id(scim_id)
      end

      # Publish domain delete event
      publish_deleted_event(scim_id)

      log_scim_operation("delete", "complete", scim_id)
      
      # RFC 7644: 204 No Content
      head :no_content
    end

  private

    def extract_correlation_id
      @correlation_id = request.headers["X-Correlation-Id"] || SecureRandom.uuid
    end

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
        TwoPercent.user_repository.upsert_from_scim(scim_hash, correlation_id: @correlation_id)
      elsif group_resource?
        TwoPercent.group_repository.upsert_from_scim(params[:resource_type], scim_hash, correlation_id: @correlation_id)
      else
        raise ArgumentError, "Unknown resource type: #{params[:resource_type]}"
      end
    end

    def find_scim_record(scim_id)
      record = 
        if user_resource?
          TwoPercent.user_repository.find_by_scim_id(scim_id)
        elsif group_resource?
          TwoPercent.group_repository.find_by_scim_id(scim_id)
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
        service: "two_percent"
      }
      log_data[:scim_id] = scim_id if scim_id

      Rails.logger.info(log_data.to_json) if defined?(Rails)
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
      "#{request.base_url}#{request.path.split('/')[0..-2].join('/')}/#{resource_type}/#{record.scim_id}"
    end
  end
end
