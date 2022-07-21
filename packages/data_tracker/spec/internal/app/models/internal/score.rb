# frozen_string_literal: true

module Internal
  class Score < ::Internal::ApplicationRecord
    DataTracker.apply(
      self,
      user: {
        created_by: { class_name: "::Internal::ManagerUser", value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) } },
        updated_by: { class_name: "::Internal::ManagerUser", value: -> { ::Internal::Current.user.becomes(::Internal::ManagerUser) } }
      }
    )
  end
end
