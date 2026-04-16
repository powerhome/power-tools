# frozen_string_literal: true

module TwoPercent
  module Scim
    # SCIM Schema definition based on RFC 7644
    class Schema
      CORE_USER_SCHEMA = "urn:ietf:params:scim:schemas:core:2.0:User"
      CORE_GROUP_SCHEMA = "urn:ietf:params:scim:schemas:core:2.0:Group"
      EXTENSION_SCHEMA = "urn:ietf:params:scim:schemas:extension:authservice:2.0:User"

      # Core User attributes per RFC 7644 Section 4.1
      CORE_USER_ATTRIBUTES = %w[
        id
        externalId
        userName
        displayName
        name
        emails
        phoneNumbers
        addresses
        photos
        userType
        title
        active
        groups
        meta
        schemas
      ].freeze

      # Core Group attributes per RFC 7644 Section 4.2
      CORE_GROUP_ATTRIBUTES = %w[
        id
        externalId
        displayName
        members
        meta
        schemas
      ].freeze

      # Extension attributes (custom per IDP)
      EXTENSION_USER_ATTRIBUTES = %w[
        department
        territory
        territoryAbbr
        role
        mfaRequired
      ].freeze

      def self.validate_user(scim_hash, require_id: true)
        # Accept either core schema or extension schemas
        validate_schemas_present(scim_hash)
        
        # Only require id for updates, not creation
        required_attrs = require_id ? %w[id externalId] : %w[externalId]
        validate_required_attributes(scim_hash, required_attrs)
        validate_attribute_types(scim_hash)
        
        # Return validated data with schemas normalized
        normalize_user(scim_hash)
      end

      def self.validate_group(scim_hash, require_id: true)
        # Accept either core schema or extension schemas
        validate_schemas_present(scim_hash)
        
        # Only require id for updates, not creation
        required_attrs = require_id ? %w[id displayName] : %w[displayName]
        validate_required_attributes(scim_hash, required_attrs)
        
        normalize_group(scim_hash)
      end

      def self.normalize_user(scim_hash)
        {
          core: extract_core_attributes(scim_hash, CORE_USER_ATTRIBUTES),
          extensions: extract_extensions(scim_hash)
        }
      end

      def self.normalize_group(scim_hash)
        {
          core: extract_core_attributes(scim_hash, CORE_GROUP_ATTRIBUTES),
          extensions: extract_extensions(scim_hash)
        }
      end

      def self.extract_core_attributes(scim_hash, allowed_attrs)
        scim_hash.slice(*allowed_attrs)
      end

      def self.extract_extensions(scim_hash)
        scim_hash.select { |key, _| key.start_with?("urn:ietf:params:scim:schemas:extension:") }
      end

      def self.validate_schemas(scim_hash, required_schemas)
        schemas = scim_hash["schemas"] || []
        missing = required_schemas - schemas
        
        if missing.any?
          raise ArgumentError, "Missing required schemas: #{missing.join(', ')}"
        end
      end

      def self.validate_schemas_present(scim_hash)
        schemas = scim_hash["schemas"] || []
        
        if schemas.empty?
          raise ArgumentError, "schemas attribute is required"
        end
      end

      def self.validate_required_attributes(scim_hash, required_attrs)
        missing = required_attrs.select { |attr| scim_hash[attr].nil? }
        
        if missing.any?
          raise ArgumentError, "Missing required attributes: #{missing.join(', ')}"
        end
      end

      def self.validate_attribute_types(scim_hash)
        # Validate complex attribute structures
        validate_name_structure(scim_hash["name"]) if scim_hash["name"]
        validate_multi_valued(scim_hash["emails"], %w[value type]) if scim_hash["emails"]
        validate_multi_valued(scim_hash["phoneNumbers"], %w[value type]) if scim_hash["phoneNumbers"]
        validate_multi_valued(scim_hash["addresses"], %w[type]) if scim_hash["addresses"]
        validate_multi_valued(scim_hash["photos"], %w[value type]) if scim_hash["photos"]
      end

      def self.validate_name_structure(name)
        return unless name.is_a?(Hash)
        
        valid_keys = %w[formatted familyName givenName middleName honorificPrefix honorificSuffix]
        invalid = name.keys - valid_keys
        
        if invalid.any?
          raise ArgumentError, "Invalid name attributes: #{invalid.join(', ')}"
        end
      end

      def self.validate_multi_valued(array, required_keys)
        return unless array.is_a?(Array)
        
        array.each_with_index do |item, idx|
          unless item.is_a?(Hash)
            raise ArgumentError, "Multi-valued attribute item #{idx} must be an object"
          end
          
          missing = required_keys - item.keys
          if missing.any?
            raise ArgumentError, "Multi-valued attribute item #{idx} missing: #{missing.join(', ')}"
          end
        end
      end
    end
  end
end
