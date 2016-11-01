module Consent
  class PermissionsGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
    argument :description, type: :string, required: false

    def create_permissions
      template "permissions.rb.erb", "app/permissions/#{file_path}.rb", assigns: {
        description: description
      }
    end
  end
end
