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

      validated_data = TwoPercent::Scim::Schema.validate_group(scim_hash, require_id: true)

      # Wrap in transaction to ensure rollback on member validation failure
      transaction do
        scim_group = find_or_initialize_by(scim_id: scim_hash["id"])
        scim_group.update_from_scim!(resource_type, validated_data, correlation_id: correlation_id)

        scim_group.replace_members(scim_hash["members"]) if scim_hash.key?("members")

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
      existing_users = validate_users_exist!(member_scim_ids)
      existing_user_ids = scim_group_memberships.pluck(:scim_user_id)

      users_to_add = existing_users.where.not(id: existing_user_ids)
      bulk_insert_memberships(users_to_add) if users_to_add.any?

      remove_memberships_not_in(member_scim_ids)
      sync_scim_data_members(existing_users)
      save!
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

  private

    # Validates that all user IDs exist in the database
    #
    # @param member_scim_ids [Array<String>] Array of SCIM user IDs to validate
    # @return [ActiveRecord::Relation] The existing users
    # @raise [ArgumentError] If any users do not exist
    def validate_users_exist!(member_scim_ids)
      existing_users = TwoPercent::ScimUser.where(scim_id: member_scim_ids)
      missing_ids = member_scim_ids - existing_users.pluck(:scim_id)

      if missing_ids.any?
        raise ArgumentError,
              "Cannot add non-existent users to group: #{missing_ids.join(', ')}"
      end

      existing_users
    end

    # Bulk insert memberships for performance
    #
    # @param users_to_add [ActiveRecord::Relation] Users to add as members
    def bulk_insert_memberships(users_to_add)
      membership_records = users_to_add.pluck(:id).map do |user_id|
        {
          scim_user_id: user_id,
          scim_group_id: id,
          created_at: Time.current,
          updated_at: Time.current,
        }
      end

      # Skip duplicates (handles race conditions and migration scenarios)
      TwoPercent::ScimGroupMembership.insert_all(
        membership_records,
        unique_by: %i[scim_user_id scim_group_id]
      )
    end

    # Remove memberships for users not in the provided list
    # Handles Rails 6.1+ empty array behavior for where.not
    #
    # @param member_scim_ids [Array<String>] SCIM IDs of users to keep
    def remove_memberships_not_in(member_scim_ids)
      # Rails 6.1+ returns empty result for where.not(column: [])
      # Must explicitly handle empty array to remove all members
      if member_scim_ids.empty?
        scim_group_memberships.delete_all
      else
        users_to_remove_ids = scim_users.where.not(scim_id: member_scim_ids).pluck(:id)
        scim_group_memberships.where(scim_user_id: users_to_remove_ids).delete_all
      end
    end

    # Sync scim_data["members"] to match join table state
    # Maintains invariant that scim_data always reflects current members
    #
    # @param existing_users [ActiveRecord::Relation] Users who should be members
    def sync_scim_data_members(existing_users)
      scim_data["members"] = existing_users.map do |user|
        {
          "value" => user.scim_id,
          "display" => user.display_name,
          "$ref" => "Users/#{user.scim_id}",
        }
      end
    end

    # Build SCIM members representation
    #
    # @return [Array<Hash>] Array of member references
    def members_representation
      scim_users.map do |user|
        {
          "value" => user.scim_id,
          "display" => user.display_name,
          "$ref" => "Users/#{user.scim_id}",
        }
      end
    end
  end
end
