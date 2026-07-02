# frozen_string_literal: true

module TwoPercent
  class ScimGroup < ApplicationRecord
    self.table_name = "two_percent_scim_groups"
    serialize :scim_data, coder: JSON

    has_many :scim_group_memberships, class_name: "TwoPercent::ScimGroupMembership",
                                      foreign_key: :scim_group_id, dependent: :destroy
    has_many :scim_users, through: :scim_group_memberships

    validates :scim_id, presence: true, uniqueness: true
    validates :external_id, presence: true
    validates :display_name, presence: true
    validates :resource_type, presence: true
    validates :scim_data, presence: true

    scope :active, -> { where(active: true) }
    scope :by_resource_type, ->(type) { where(resource_type: type) }

    # Creates or updates a group from SCIM data
    #
    # Generates a UUID for the id field if not present (for POST/create operations).
    # Validates the SCIM data against the Group schema before persisting.
    #
    # @param resource_type [String] The resource type (e.g., "Groups", "Departments", "Territories")
    # @param scim_hash [Hash] SCIM Group resource hash conforming to RFC 7643
    # @param correlation_id [String, nil] Optional correlation ID for tracking
    #   changes across network hops (e.g., App A -> App B -> App C)
    # @return [TwoPercent::ScimGroup] The persisted group record
    # @raise [TwoPercent::Scim::ValidationError] If SCIM data fails schema validation
    def self.upsert_from_scim(resource_type, scim_hash, correlation_id: nil)
      # Generate SCIM id (stored as scim_id) if not provided (typical for POST operations)
      scim_hash = scim_hash.dup
      scim_hash["id"] ||= SecureRandom.uuid

      # Extract members before validation to prevent storage in scim_data JSONB
      members = scim_hash.delete("members")

      validated_data = TwoPercent::Scim::Schema.validate_group(scim_hash, require_id: true)

      # Wrap in transaction to ensure rollback on member validation failure
      transaction do
        scim_group = find_or_initialize_by(scim_id: scim_hash["id"])
        scim_group.update_from_scim!(resource_type, validated_data, correlation_id: correlation_id)

        # Sync members to join table only (never stored in scim_data)
        scim_group.replace_members(members) if members

        scim_group
      end
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
    # Returns key attributes for event payloads.
    # Members are NOT included - consumers should query TwoPercent models directly for current state.
    # @return [Hash] Domain attributes
    def to_domain_attributes
      {
        scim_id: scim_id,
        external_id: external_id,
        display_name: display_name,
        resource_type: resource_type,
        active: active,
      }.compact
    end

    # Returns full SCIM representation for HTTP responses
    #
    # @return [Hash] RFC 7644 compliant SCIM Group resource
    def to_scim_representation
      representation = scim_data.merge(
        "id" => scim_id,
        "meta" => {
          "resourceType" => resource_type,
          "created" => created_at.iso8601,
          "lastModified" => updated_at.iso8601,
        }
      )

      representation["members"] = members_representation if scim_users.loaded?
      representation
    end

    def update_from_scim!(resource_type, validated_data, correlation_id: nil)
      core_data = validated_data[:core]
      self.scim_data = core_data.merge(validated_data[:extensions])
      self.scim_id = core_data["id"]
      self.external_id = core_data["externalId"]
      self.display_name = core_data["displayName"]
      self.resource_type = resource_type

      extension_data = validated_data[:extensions]
      self.active = extension_data.dig("urn:ietf:params:scim:schemas:extension:authservice:2.0:Group",
                                       "active") != false
      self.correlation_id = correlation_id
      save!
    end

    def replace_members(members_array)
      member_scim_ids = members_array.filter_map { |m| m["value"] }

      # Get current member scim_ids efficiently (just IDs, no full records)
      current_member_scim_ids = scim_group_memberships
                                .joins(:scim_user)
                                .pluck("two_percent_scim_users.scim_id")

      # Calculate diff in Ruby (cheap for ID arrays)
      scim_ids_to_add = member_scim_ids - current_member_scim_ids
      scim_ids_to_remove = current_member_scim_ids - member_scim_ids

      # Only validate and add NEW members (not existing ones)
      add_members_by_scim_id(scim_ids_to_add) if scim_ids_to_add.any?

      # Only remove members that need removing
      remove_members_by_scim_id(scim_ids_to_remove) if scim_ids_to_remove.any?
    end

    # Extracts a nested attribute from the scim_data JSON
    #
    # @param path [String] Dot-separated path to the attribute (e.g., "displayName")
    # @return [Object, nil] The attribute value or nil if not found
    # @example
    #   group.scim_attribute("members.0.value") # => "user-id-123"
    def scim_attribute(path)
      keys = path.split(".")
      scim_data.dig(*keys)
    end

    # Build SCIM members representation from join table
    # Optimized to bypass ActiveRecord and load only needed columns
    #
    # @return [Array<Hash>] Array of member references
    def members_representation
      scim_group_memberships
        .joins(:scim_user)
        .pluck("two_percent_scim_users.scim_id", "two_percent_scim_users.display_name")
        .map do |scim_id, display_name|
          {
            "value" => scim_id,
            "display" => display_name,
            "$ref" => "Users/#{scim_id}",
          }
        end
    end

    # Build members array with value field only (for PatchProcessor)
    # Uses pluck to avoid loading full AR objects
    #
    # @return [Array<Hash>] Array of member values
    def members_for_patch
      scim_group_memberships
        .joins(:scim_user)
        .pluck("two_percent_scim_users.scim_id")
        .map { |id| { "value" => id } }
    end

  private

    # Add members by SCIM IDs, validating they exist
    #
    # @param scim_ids_to_add [Array<String>] SCIM IDs of users to add
    def add_members_by_scim_id(scim_ids_to_add)
      return if scim_ids_to_add.empty?

      users_to_add = validate_and_fetch_users(scim_ids_to_add)
      bulk_insert_new_memberships(users_to_add)
    end

    # Remove members by SCIM IDs (direct, no JOIN needed)
    #
    # @param scim_ids_to_remove [Array<String>] SCIM IDs of users to remove
    def remove_members_by_scim_id(scim_ids_to_remove)
      return if scim_ids_to_remove.empty?

      # Direct delete using SCIM IDs via subquery
      scim_group_memberships
        .where(scim_user_id: TwoPercent::ScimUser.where(scim_id: scim_ids_to_remove).select(:id))
        .delete_all
    end

    # Validate users exist and return them
    #
    # @param scim_ids [Array<String>] SCIM IDs to validate
    # @return [ActiveRecord::Relation] The existing users
    # @raise [ArgumentError] If any users do not exist
    def validate_and_fetch_users(scim_ids)
      users = TwoPercent::ScimUser.where(scim_id: scim_ids)
      missing_ids = scim_ids - users.pluck(:scim_id)

      if missing_ids.any?
        raise ArgumentError,
              "Cannot add non-existent users to group: #{missing_ids.join(', ')}"
      end

      users
    end

    # Bulk insert memberships for the given users
    #
    # @param users [ActiveRecord::Relation] Users to add as members
    def bulk_insert_new_memberships(users)
      membership_records = users.pluck(:id).map do |user_id|
        {
          scim_user_id: user_id,
          scim_group_id: id,
          created_at: Time.current,
          updated_at: Time.current,
        }
      end

      TwoPercent::ScimGroupMembership.insert_all(
        membership_records,
        unique_by: %i[scim_user_id scim_group_id]
      )
    end
  end
end
