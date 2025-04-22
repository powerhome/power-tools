# frozen_string_literal: true

module TwoPercent
  class GroupMembership < TwoPercent::ApplicationRecord
    belongs_to :user
    belongs_to :group, class_name: "TwoPercent::Groups::Group"

    validates :group_id, uniqueness: { scope: :user_id }
  end
end
