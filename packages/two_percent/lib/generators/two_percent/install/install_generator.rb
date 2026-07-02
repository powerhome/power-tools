# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module TwoPercent
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Installs TwoPercent SCIM integration with migrations and initializer"

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_migrations
        migration_template(
          "create_two_percent_scim_users.rb.erb",
          "db/migrate/create_two_percent_scim_users.rb"
        )

        migration_template(
          "create_two_percent_scim_groups.rb.erb",
          "db/migrate/create_two_percent_scim_groups.rb"
        )

        migration_template(
          "create_two_percent_scim_group_memberships.rb.erb",
          "db/migrate/create_two_percent_scim_group_memberships.rb"
        )

        migration_template(
          "add_unique_index_to_scim_users_external_id.rb.erb",
          "db/migrate/add_unique_index_to_scim_users_external_id.rb"
        )

        migration_template(
          "add_unique_composite_index_to_scim_groups.rb.erb",
          "db/migrate/add_unique_composite_index_to_scim_groups.rb"
        )
      end

      def copy_initializer
        template "two_percent.rb.erb", "config/initializers/two_percent.rb"
      end

      def show_readme
        readme "INSTALL_README" if behavior == :invoke
      end
    end
  end
end
