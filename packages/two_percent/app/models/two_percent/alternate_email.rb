# frozen_string_literal: true

module TwoPercent
  class AlternateEmail < TwoPercent::ApplicationRecord
    belongs_to :user
  end
end
