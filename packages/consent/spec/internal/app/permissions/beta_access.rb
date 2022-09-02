# frozen_string_literal: true

Consent.define :beta, "Beta access" do
  view :role, "User role" do |user|
    { example_role: { id: user.role_id } }
  end

  action :super_ai, "Beta access to the Super AI"
  action :report_3d, "Beta access to the 3D report", views: %i[role]
end
