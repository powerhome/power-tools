module TwoPercent
  class User < ApplicationRecord
    has_many :alternate_emails
    has_many :phone_numbers
    has_many :memberships, class_name: "TwoPercent::GroupMemembership"
    has_many :groups, through: :memberships
  end
end
