# frozen_string_literal: true

module Internal
  class Sale < ::Internal::ApplicationRecord
    DataTracker.apply(self)
  end
end
