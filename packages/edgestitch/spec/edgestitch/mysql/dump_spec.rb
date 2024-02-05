# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edgestitch::Mysql::Dump do
  describe ".sanitize_migration_timestamps" do
    it "breaks the insert down in different lines" do
      insert = "INSERT INTO schema_migrations VALUES ('20240102123421'),('20240102223421')," \
               "('20240102323421'),('20240102423421'),('20240102523421');"

      sanitized = Edgestitch::Mysql::Dump.sanitize_migration_timestamps(insert)

      # rubocop:disable Rails/SquishedSQLHeredocs
      expect(sanitized).to eql <<~SQL.strip
        INSERT INTO schema_migrations VALUES
        ('20240102123421')
        ,('20240102223421')
        ,('20240102323421')
        ,('20240102423421')
        ,('20240102523421')
        ;
      SQL
      # rubocop:enable Rails/SquishedSQLHeredocs
    end
  end
end
