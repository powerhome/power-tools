# frozen_string_literal: true

module Internal
  class Lead < ::Internal::ApplicationRecord
    DataTracker.apply(self)
  end
end
