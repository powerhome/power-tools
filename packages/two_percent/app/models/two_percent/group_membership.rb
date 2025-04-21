module TwoPercent
  class GroupMembership < ApplicationRecord
    belongs_to :user
    belongs_to :group

    validates :group_id, uniqueness: { scope: :user_id }
  end
end
