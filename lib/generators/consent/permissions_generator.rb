# frozen_string_literal: true

module Consent
  class PermissionsGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)
    argument :description, type: :string, required: false

    def create_permissions
      template(
        'permissions.rb.erb',
        "app/permissions/#{file_path}.rb",
        assigns: { description: description }
      )

      template(
        'permissions_spec.rb.erb',
        "spec/permissions/#{file_path}_spec.rb"
      )
    end
  end
end
