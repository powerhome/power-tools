# frozen_string_literal: true

module TwoPercent
  class ScimUser < ApplicationRecord
    self.table_name = "two_percent_scim_users"
    serialize :scim_data, coder: JSON

    has_many :scim_group_memberships, class_name: "TwoPercent::ScimGroupMembership",
                                      foreign_key: :scim_user_id, dependent: :destroy
    has_many :scim_groups, through: :scim_group_memberships

    validates :scim_id, presence: true, uniqueness: true
    validates :external_id, presence: true
    validates :scim_data, presence: true

    scope :active, -> { where(active: true) }

    # Creates or updates a user from SCIM data
    #
    # Generates a UUID for the id field if not present (for POST/create operations).
    # Validates the SCIM data against the User schema before persisting.
    #
    # @param scim_hash [Hash] SCIM User resource hash conforming to RFC 7643
    # @param correlation_id [String, nil] Optional correlation ID for tracking
    #   changes across network hops (e.g., App A -> App B -> App C)
    # @return [TwoPercent::ScimUser] The persisted user record
    # @raise [TwoPercent::Scim::ValidationError] If SCIM data fails schema validation
    def self.upsert_from_scim(scim_hash, correlation_id: nil)
      # Generate SCIM id (stored as scim_id) if not provided (typical for POST operations)
      scim_hash = scim_hash.dup
      scim_hash["id"] ||= SecureRandom.uuid

      # Extract groups before validation to prevent storage in scim_data JSONB
      # Groups are synced to join table only (single source of truth)
      groups = scim_hash.delete("groups")

      validated_data = TwoPercent::Scim::Schema.validate_user(scim_hash, require_id: true)
      scim_user = find_or_initialize_by(scim_id: scim_hash["id"])
      scim_user.update_from_scim!(validated_data, groups, correlation_id: correlation_id)
      scim_user
    end

    def self.find_by_scim_id(scim_id)
      find_by(scim_id: scim_id)
    end

    def self.exists_by_scim_id?(scim_id)
      exists?(scim_id: scim_id)
    end

    def self.destroy_by_scim_id(scim_id)
      find_by_scim_id(scim_id)&.destroy
    end

    # Extracts domain attributes for publishing in domain events
    #
    # Returns key attributes for event payloads (thin events - no associations).
    # Group memberships are queried separately by consumers who need them.
    #
    # @return [Hash] Domain attributes
    def to_domain_attributes
      {
        scim_id: scim_id,
        external_id: external_id,
        user_name: user_name,
        display_name: display_name,
        email: email,
        active: active,
      }.compact
    end

    # Returns full SCIM representation for HTTP responses
    #
    # @return [Hash] RFC 7644 compliant SCIM User resource
    def to_scim_representation
      representation = scim_data.merge(
        "id" => scim_id,
        "meta" => {
          "resourceType" => "User",
          "created" => created_at.iso8601,
          "lastModified" => updated_at.iso8601,
        }
      )

      # Build groups dynamically from join table (RFC 7643: User.groups is read-only)
      # Single source of truth is join table - only included when association is loaded
      representation["groups"] = groups_representation if scim_groups.loaded?

      representation
    end

    # Build SCIM groups representation dynamically from join table
    # Per RFC 7643 Section 4.1.2, User.groups is read-only and must reflect Group memberships
    #
    # @return [Array<Hash>] Array of group references with SCIM-compliant attributes
    def groups_representation
      scim_groups.map do |group|
        {
          "value" => group.scim_id,
          "display" => group.display_name,
          "$ref" => "#{group.resource_type}/#{group.scim_id}",
          "type" => group.resource_type,
        }
      end
    end

    # Updates user attributes from validated SCIM data
    #
    # NOTE: This method processes the User.groups array from the request payload
    # and syncs group memberships, which is a deviation from strict RFC 7643 compliance
    # (User.groups is specified as read-only in Section 4.1.2). This behavior is
    # intentionally maintained for compatibility with existing SCIM clients that rely
    # on this functionality for bulk sync operations.
    #
    # @param validated_data [Hash] Validated SCIM data with :core and :extensions keys
    # @param groups_data [Array<Hash>, nil] Groups array extracted before validation
    # @param correlation_id [String, nil] Optional correlation ID for tracking
    def update_from_scim!(validated_data, groups_data, correlation_id: nil)
      core_data = validated_data[:core]
      self.scim_data = core_data.merge(validated_data[:extensions])
      self.scim_id = core_data["id"]
      self.external_id = core_data["externalId"]
      self.user_name = core_data["userName"]
      self.display_name = core_data["displayName"]
      self.email = core_data.dig("emails", 0, "value")
      self.active = core_data.fetch("active", true)
      self.correlation_id = correlation_id
      save!
      # Sync groups to join table only (never stored in scim_data)
      sync_groups(groups_data) if groups_data
    end

    # Syncs user's group memberships from SCIM groups array
    #
    # Accepts a groups array from SCIM User payload and updates associations.
    # This enables bulk sync operations where clients send User.groups arrays.
    #
    # @param groups_data [Array<Hash>] Array of group references with "value" (scim_id)
    # @example
    #   sync_groups([{"value" => "group-123", "display" => "Engineering"}])
    #   sync_groups([]) # Clears all group memberships
    def sync_groups(groups_data)
      return if groups_data.nil?

      group_ids = groups_data.filter_map { |g| g["value"] }
      groups = TwoPercent::ScimGroup.where(scim_id: group_ids)
      self.scim_groups = groups
    end

    # Extracts a nested attribute from the scim_data JSON
    #
    # @param path [String] Dot-separated path to the attribute (e.g., "name.givenName")
    # @return [Object, nil] The attribute value or nil if not found
    # @example
    #   user.scim_attribute("emails.0.value") # => "user@example.com"
    def scim_attribute(path)
      keys = path.split(".")
      scim_data.dig(*keys)
    end

    def extension_attributes(schema_urn = nil)
      if schema_urn
        scim_data[schema_urn] || {}
      else
        scim_data.select { |k, _| k.start_with?("urn:ietf:params:scim:schemas:extension:") }
      end
    end

  private

    def group_memberships_attributes
      scim_groups.map do |group|
        {
          scim_id: group.scim_id,
          display_name: group.display_name,
          resource_type: group.resource_type,
        }
      end
    end
  end
end
