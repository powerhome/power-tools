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
    # @param correlation_id [String, nil] Optional correlation ID for tracking changes across network hops (e.g., App A -> App B -> App C)
    # @return [TwoPercent::ScimGroup] The persisted group record
    # @raise [TwoPercent::Scim::ValidationError] If SCIM data fails schema validation
    def self.upsert_from_scim(resource_type, scim_hash, correlation_id: nil)
      # Generate ID if not present (for POST/create operations)
      scim_hash = scim_hash.dup
      scim_hash["id"] ||= SecureRandom.uuid

      validated_data = TwoPercent::Scim::Schema.validate_group(scim_hash, require_id: true)
      scim_group = find_or_initialize_by(scim_id: scim_hash["id"])
      scim_group.update_from_scim!(resource_type, validated_data, correlation_id: correlation_id)

      scim_group.sync_members(scim_hash["members"], correlation_id) if scim_hash["members"].present?

      scim_group
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
    # Uses the configured group_mapper to extract relevant attributes.
    #
    # @return [Hash] Domain attributes configured via TwoPercent.group_mapper
    def to_domain_attributes
      TwoPercent.group_mapper.extract_domain_attributes(self) || {}
    end

    def to_scim_representation
      representation = TwoPercent.group_mapper.build_scim_representation(self, resource_type: resource_type)

      # Include members from associations if loaded or present
      if scim_users.loaded? || scim_users.any?
        representation["members"] = scim_users.map do |user|
          {
            "value" => user.scim_id,
            "display" => user.display_name,
            "$ref" => "Users/#{user.scim_id}",
          }
        end
      end

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

    def sync_members(members_array, correlation_id)
      member_scim_ids = members_array.filter_map { |m| m["value"] }
      existing_user_ids = scim_group_memberships.pluck(:scim_user_id)

      users_to_add = TwoPercent::ScimUser.where(scim_id: member_scim_ids).where.not(id: existing_user_ids)

      users_to_add.each do |user|
        TwoPercent::ScimGroupMembership.create!(
          scim_user: user,
          scim_group: self,
          correlation_id: correlation_id
        )
      end

      users_to_remove_ids = scim_users.where.not(scim_id: member_scim_ids).pluck(:id)
      scim_group_memberships.where(scim_user_id: users_to_remove_ids).destroy_all
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
  end
end
