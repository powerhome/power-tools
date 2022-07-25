# frozen_string_literal: true

module Internal
  class Score < ::Internal::ApplicationRecord
    belongs_to :created_by, class_name: "::Internal::ManagerUser"

    track_audit_data(
      user: {
        created_by: { value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) } },
        updated_by: {
          class_name: "::Internal::ManagerUser",
          value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) },
        },
      }
    )
  end
end
