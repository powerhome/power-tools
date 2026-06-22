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
          # Note: DELETE operations don't return a record, but still need to publish events
          if record || operation[:method] == "DELETE"
            publish_domain_event(operation[:method], resource_type, record,
                                 id)
          end
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
      when "PATCH"
        persist_patch(resource_type, id, data)
      when "PUT"
        persist_update(resource_type, id, data)
      when "DELETE"
        persist_delete(resource_type, id)
        nil # No record to return for deletes
      else
        raise ArgumentError, "Unknown HTTP method: #{method}"
      end
    end

    def persist_create(resource_type, data)
      if resource_type == "Users"
        TwoPercent::ScimUser.upsert_from_scim(data, correlation_id: @correlation_id)
      else
        TwoPercent::ScimGroup.upsert_from_scim(resource_type, data, correlation_id: @correlation_id)
      end
    end

    def persist_patch(resource_type, id, data)
      # PATCH - apply operations to existing resource
      record = find_record(resource_type, id)

      # RFC 7643: Validate read-only attributes for User resources
      validate_patch_operations!(resource_type, data) if resource_type == "Users"

      # Apply SCIM PATCH operations (RFC 7644 compliance)
      processor = TwoPercent::Scim::PatchProcessor.new(data)
      current_scim_data = record.scim_data || {}
      patched_data = processor.apply_to_hash(current_scim_data)

      # Persist patched data
      patched_data["id"] = id # Ensure ID is present
      if resource_type == "Users"
        TwoPercent::ScimUser.upsert_from_scim(patched_data, correlation_id: @correlation_id)
      else
        TwoPercent::ScimGroup.upsert_from_scim(resource_type, patched_data, correlation_id: @correlation_id)
      end
    end

    def persist_update(resource_type, id, data)
      # PUT - replace entire resource
      data_with_id = data.merge("id" => id)
      if resource_type == "Users"
        TwoPercent::ScimUser.upsert_from_scim(data_with_id, correlation_id: @correlation_id)
      else
        TwoPercent::ScimGroup.upsert_from_scim(resource_type, data_with_id, correlation_id: @correlation_id)
      end
    end

    def persist_delete(resource_type, id)
      if resource_type == "Users"
        TwoPercent::ScimUser.destroy_by_scim_id(id)
      else
        TwoPercent::ScimGroup.destroy_by_scim_id(id)
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

    def find_record(resource_type, scim_id)
      record =
        if resource_type == "Users"
          TwoPercent::ScimUser.find_by_scim_id(scim_id)
        else
          TwoPercent::ScimGroup.find_by_scim_id(scim_id)
        end

      raise ActiveRecord::RecordNotFound, "Resource \"#{scim_id}\" not found" unless record

      record
    end

    # Validate PATCH operations against RFC 7643 read-only attributes
    # @raise [TwoPercent::ReadOnlyAttributeError] if attempting to modify read-only User.groups
    def validate_patch_operations!(resource_type, patch_request)
      return unless resource_type == "Users"

      operations = patch_request["Operations"] || patch_request[:Operations]
      return unless operations.is_a?(Array)

      operations.each do |operation|
        path = operation["path"] || operation[:path]
        next unless path

        # Extract base attribute from path (e.g., "groups" from "groups[value eq '123']")
        base_path = path.split(/[\.\[]/).first

        if base_path == "groups"
          # RFC 7643 Section 4.1.2: User.groups is read-only
          # RFC 7644 Section 3.5.2: Return 400 with scimType="mutability"
          raise TwoPercent::ReadOnlyAttributeError,
                "Attribute 'groups' is read-only per SCIM RFC 7643. Manage group membership via PATCH /scim/Groups/{id}"
        end
      end
    end
  end
end
