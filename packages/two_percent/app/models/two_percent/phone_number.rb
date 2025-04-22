# frozen_string_literal: true

module TwoPercent
  class PhoneNumber < TwoPercent::ApplicationRecord
    belongs_to :user
  end
end
