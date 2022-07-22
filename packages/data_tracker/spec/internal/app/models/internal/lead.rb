# frozen_string_literal: true

module Internal
  class Lead < ::Internal::ApplicationRecord
    track_data user: true, department: true
  end
end
