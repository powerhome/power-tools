# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

# Helper methods to get database configurations, accounting for changes between rails versions
module DatabaseHelper
  class DBConfig
    VALUES = {
      source: { key: "primary", name: "test_source" },
      dump: { key: "test_dump", name: "test_dump" },
    }.freeze

    def dump_db_name
      VALUES[:dump][:name]
    end

    def dump_db_client
      @dump_db_client ||= Mysql2::Client.new(test_dump_database_config)
    end

    def test_dump_database_config
      ActiveRecord::Base.configurations.configs_for(env_name: Rails.env,
                                                    name: VALUES[:dump][:key]).configuration_hash
    rescue ArgumentError
      ActiveRecord::Base.configurations.configs_for(env_name: Rails.env,
                                                    spec_name: VALUES[:dump][:key]).config
    end

    def source_db_name
      VALUES[:source][:name]
    end

    def source_db_client
      @source_db_client ||= Mysql2::Client.new(test_source_database_config)
    end

    def test_source_database_config
      ActiveRecord::Base.configurations.configs_for(env_name: Rails.env,
                                                    name: VALUES[:source][:key]).configuration_hash
    rescue ArgumentError
      ActiveRecord::Base.configurations.configs_for(env_name: Rails.env,
                                                    spec_name: VALUES[:source][:key]).config
    end
  end
  private_constant :DBConfig

  # Methods available for use during specs
  delegate :dump_db_name, :dump_db_client, :source_db_name, :source_db_client, to: :db_config

  def setup_source_data
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    insert_user_sql = <<-SQL.squish
      INSERT INTO users (id, encrypted_password, ssn, passport_number, license_number, date_of_birth, dob, notes, body,
       compensation, income, email, email2, address, address2, created_at, updated_at)
      VALUES (1, 'encrypted123', '123-45-6789', 'P123456789', 'L123456789', '1990-01-01', '1990-01-01',
        'Private notes', 'Body text', 50000.00, 60000.00, 'test@example.com', 'test2@example.com', '123 Main St',
        'Apt 1', '#{now}', '#{now}')
    SQL
    source_db_client.query(insert_user_sql)
  end

private

  def db_config
    @db_config ||= DBConfig.new
  end
end

RSpec.configure do |config|
  config.include DatabaseHelper
end
