# frozen_string_literal: true

module Internal
  class Sale < ::Internal::ApplicationRecord
    track_data user: true
  end
end
