# frozen_string_literal: true

module TwoPercent
  class BulkProcessor
    def initialize(operations, correlation_id: nil)
      @operations = operations
      @correlation_id = correlation_id
    end

    def dispatch
      @operations.each do |operation|
        resource_type, id = parse_path(operation[:path])
        
        # Persist data to two_percent tables first (wrapped in transaction for bulk integrity)
        ActiveRecord::Base.transaction do
          record = persist_bulk_operation(operation[:method], resource_type, id, operation[:data])
          
          # Publish domain events based on operation
          publish_domain_event(operation[:method], resource_type, record, id) if record
        end
      end
    end

  private

    def parse_path(path)
      _, resource_type, id = path.split("/")

      [resource_type, id]
    end

    def persist_bulk_operation(method, resource_type, id, data)
      case method
      when "POST"
        persist_create(resource_type, data)
      when "PATCH", "PUT"
        persist_update(resource_type, id, data)
      when "DELETE"
        persist_delete(resource_type, id)
        nil  # No record to return for deletes
      else
        raise ArgumentError, "Unknown HTTP method: #{method}"
      end
    end

    def persist_create(resource_type, data)
      if resource_type == "Users"
        TwoPercent.user_repository.upsert_from_scim(data, correlation_id: @correlation_id)
      else
        TwoPercent.group_repository.upsert_from_scim(resource_type, data, correlation_id: @correlation_id)
      end
    end

    def persist_update(resource_type, id, data)
      # PATCH/PUT - merge with id and let repository handle
      data_with_id = data.merge("id" => id)
      if resource_type == "Users"
        TwoPercent.user_repository.upsert_from_scim(data_with_id, correlation_id: @correlation_id)
      else
        TwoPercent.group_repository.upsert_from_scim(resource_type, data_with_id, correlation_id: @correlation_id)
      end
    end

    def persist_delete(resource_type, id)
      if resource_type == "Users"
        TwoPercent.user_repository.destroy_by_scim_id(id)
      else
        TwoPercent.group_repository.destroy_by_scim_id(id)
      end
    end

    def publish_domain_event(method, resource_type, record, id)
      case method
      when "POST"
        publish_created_event(resource_type, record)
      when "PATCH", "PUT"
        publish_updated_event(resource_type, record)
      when "DELETE"
        publish_deleted_event(resource_type, id)
      end
    end

    def publish_created_event(resource_type, record)
      if resource_type == "Users"
        TwoPercent::Domain::Events::UserCreated.create(
          user_attributes: record.to_domain_attributes,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupCreated.create(
          group_attributes: record.to_domain_attributes,
          resource_type: resource_type,
          correlation_id: @correlation_id
        )
      end
    end

    def publish_updated_event(resource_type, record)
      if resource_type == "Users"
        TwoPercent::Domain::Events::UserUpdated.create(
          user_attributes: record.to_domain_attributes,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupUpdated.create(
          group_attributes: record.to_domain_attributes,
          resource_type: resource_type,
          correlation_id: @correlation_id
        )
      end
    end

    def publish_deleted_event(resource_type, id)
      if resource_type == "Users"
        TwoPercent::Domain::Events::UserDeleted.create(
          user_id: id,
          correlation_id: @correlation_id
        )
      else
        TwoPercent::Domain::Events::GroupDeleted.create(
          group_id: id,
          resource_type: resource_type,
          correlation_id: @correlation_id
        )
      end
    end
  end
end
