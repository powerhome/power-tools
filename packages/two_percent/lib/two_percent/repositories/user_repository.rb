# frozen_string_literal: true

module TwoPercent
  module Repositories
    # Repository interface for SCIM Users
    # Apps must implement a class that includes this module and implements these methods
    module UserRepository
      # Create or update a user from validated SCIM data
      # @param scim_hash [Hash] Validated SCIM user data
      # @param correlation_id [String, nil] Request correlation ID
      # @return [Object] The user record (app's model instance)
      def self.upsert_from_scim(scim_hash, correlation_id: nil)
        raise NotImplementedError, "#{self} must implement #upsert_from_scim"
      end

      # Find user by SCIM ID
      # @param scim_id [String] The SCIM id
      # @return [Object, nil] The user record or nil
      def self.find_by_scim_id(scim_id)
        raise NotImplementedError, "#{self} must implement #find_by_scim_id"
      end

      # Check if user exists by SCIM ID
      # @param scim_id [String] The SCIM id
      # @return [Boolean]
      def self.exists_by_scim_id?(scim_id)
        raise NotImplementedError, "#{self} must implement #exists_by_scim_id?"
      end

      # Destroy user by SCIM ID
      # @param scim_id [String] The SCIM id
      # @return [Boolean] true if destroyed, false if not found
      def self.destroy_by_scim_id(scim_id)
        raise NotImplementedError, "#{self} must implement #destroy_by_scim_id"
      end

      # Instance method: Convert to domain attributes for events
      # @return [Hash] Domain attributes (NOT SCIM-specific)
      def to_domain_attributes
        raise NotImplementedError, "#{self.class} must implement #to_domain_attributes"
      end

      # Instance method: Get the SCIM ID
      # @return [String] The SCIM id
      def scim_id
        raise NotImplementedError, "#{self.class} must implement #scim_id"
      end

      # Instance method: Convert to SCIM representation (RFC 7644)
      # @return [Hash] Full SCIM user resource
      def to_scim_representation
        raise NotImplementedError, "#{self.class} must implement #to_scim_representation"
      end
    end
  end
end
