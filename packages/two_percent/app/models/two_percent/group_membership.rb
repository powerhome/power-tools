module TwoPercent
  class GroupMembership < ApplicationRecord
    belongs_to :user
    belongs_to :group
  end
end
