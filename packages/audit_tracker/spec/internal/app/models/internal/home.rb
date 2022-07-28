# frozen_string_literal: true

module Internal
  class Home < ::Internal::ApplicationRecord
    track_audit_data user: true
  end
end
