# frozen_string_literal: true

module TwoPercent
  module Domain
    module Events
      # Domain event: User was created
      class UserCreated < BaseEvent
        event_name "user.created"
        
        attribute :user_attributes  # Domain attributes, not SCIM
        
        def user_id
          user_attributes[:scim_id]
        end
      end
      
      # Domain event: User was updated  
      class UserUpdated < BaseEvent
        event_name "user.updated"
        
        attribute :user_attributes
        
        def user_id
          user_attributes[:scim_id]
        end
      end
      
      # Domain event: User was deleted
      class UserDeleted  < BaseEvent
        event_name "user.deleted"
        
        attribute :user_id  # Just the ID for deletion
      end
    end
  end
end
