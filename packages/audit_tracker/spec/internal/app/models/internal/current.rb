# frozen_string_literal: true

module Internal
  class Current < ActiveSupport::CurrentAttributes
    attribute :user
  end
end
