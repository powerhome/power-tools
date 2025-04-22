module TwoPercent
  module Groups
    class Group < TwoPercent::ApplicationRecord
      has_many :memberships, class_name: "TwoPercent::GroupMembership"
      has_many :members, through: :memberships
    end
  end
end
