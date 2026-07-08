# frozen_string_literal: true

module TwoPercent
  class ScimGroupMembership < ApplicationRecord
    self.table_name = "two_percent_scim_group_memberships"

    belongs_to :scim_user, class_name: "TwoPercent::ScimUser",
                           foreign_key: :scim_user_id
    belongs_to :scim_group, class_name: "TwoPercent::ScimGroup",
                            foreign_key: :scim_group_id

    validates :scim_user_id, presence: true
    validates :scim_group_id, presence: true
    validates :scim_user_id, uniqueness: { scope: :scim_group_id, message: "already a member of this group" }

    def self.find_or_create_membership(scim_user:, scim_group:)
      find_or_create_by!(
        scim_user_id: scim_user.id,
        scim_group_id: scim_group.id
      )
    end

    def self.remove_membership(scim_user:, scim_group:)
      find_by(scim_user_id: scim_user.id, scim_group_id: scim_group.id)&.destroy
    end
  end
end
