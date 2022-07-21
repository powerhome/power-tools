# frozen_string_literal: true

DataTracker.setup do
  tracker(:user) do
    create :created_by, foreign_key: :created_by_id, class_name: "::Internal::User"
    update :updated_by, foreign_key: :updated_by_id, class_name: "::Internal::User"
    value { Internal::Current.user }
  end

  tracker(:department) do
    create :created_by_department, foreign_key: :created_by_department_id, class_name: "::Internal::Department"
    update :updated_by_department, foreign_key: :updated_by_department_id, class_name: "::Internal::Department"
    value { Internal::Current.user&.department }
  end
end
