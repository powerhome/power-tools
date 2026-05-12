# frozen_string_literal: true

module TwoPercent
  module Domain
    module Events
      # Domain event: Group was created
      class GroupCreated < BaseEvent
        event_name "group.created"

        attribute :group_attributes  # Domain attributes, not SCIM
        attribute :resource_type     # Groups, Departments, etc.

        def group_id
          group_attributes[:scim_id]
        end

        # Apply this event to a domain model class
        def apply_to_model(model_class)
          model_class.syncable_model.sync_created(group_attributes, model_class)
        end
      end

      # Domain event: Group was updated
      class GroupUpdated < BaseEvent
        event_name "group.updated"

        attribute :group_attributes
        attribute :resource_type

        def group_id
          group_attributes[:scim_id]
        end

        # Apply this event to a domain model class
        def apply_to_model(model_class)
          model_class.syncable_model.sync_updated(group_attributes, model_class)
        end
      end

      # Domain event: Group was deleted
      class GroupDeleted < BaseEvent
        event_name "group.deleted"

        attribute :group_id # Just the ID for deletion
        attribute :resource_type

        # Apply this event to a domain model class
        def apply_to_model(model_class)
          model_class.syncable_model.sync_deleted(group_id, model_class)
        end
      end
    end
  end
end
