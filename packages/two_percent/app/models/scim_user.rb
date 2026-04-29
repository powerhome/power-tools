# frozen_string_literal: true

class ScimUser < ActiveRecord::Base
  self.table_name = "two_percent_scim_users"
  serialize :scim_data, coder: JSON

  has_many :scim_group_memberships, class_name: "ScimGroupMembership",
           foreign_key: :scim_user_id, dependent: :destroy
  has_many :scim_groups, through: :scim_group_memberships

  validates :scim_id, presence: true, uniqueness: true
  validates :external_id, presence: true
  validates :scim_data, presence: true

  scope :active, -> { where(active: true) }

  # ===== TwoPercent::Repositories::UserRepository Interface =====

  def self.upsert_from_scim(scim_hash, correlation_id: nil)
    # Generate ID if not present (for POST/create operations)
    scim_hash = scim_hash.dup
    scim_hash["id"] ||= SecureRandom.uuid
    
    validated_data = TwoPercent::Scim::Schema.validate_user(scim_hash, require_id: true)
    scim_user = find_or_initialize_by(scim_id: scim_hash["id"])
    scim_user.update_from_scim!(validated_data, correlation_id: correlation_id)
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

  def to_domain_attributes
    attributes = TwoPercent.user_mapper.extract_domain_attributes(self) || {}
    
    # Include group memberships from associations
    if scim_groups.loaded? || scim_groups.any?
      attributes[:groups] = scim_groups.map do |group|
        {
          scim_id: group.scim_id,
          display_name: group.display_name,
          resource_type: group.resource_type
        }
      end
    end
    
    attributes
  end

  def to_scim_representation
    TwoPercent.user_mapper.build_scim_representation(self, resource_type: "User")
  end

  # ===== App-specific Methods =====

  def update_from_scim!(validated_data, correlation_id: nil)
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
  end

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
end
