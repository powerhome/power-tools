# frozen_string_literal: true

require "mysql2"

module DatabaseSetup
  extend DatabaseHelper

  class << self
    def prepare_test_databases!
      recreate_databases
      reload_schemas
    end

    def reset_users_tables!
      source_db_client.query("TRUNCATE TABLE users")
      begin
        dump_db_client.query("TRUNCATE TABLE users")
      rescue Mysql2::Error
        load Rails.root.join("db", "test_dump_schema.rb")
        dump_db_client.query("TRUNCATE TABLE users")
      end
    end

  private

    def recreate_databases
      ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
        recreate_database(db_config.configuration_hash)
      end

      ActiveRecord::Base.connection_handler.clear_all_connections!
    end

    def recreate_database(hash)
      client = Mysql2::Client.new(
        host: hash[:host],
        username: hash[:username],
        password: hash[:password],
        port: hash[:port]
      )
      client.query("DROP DATABASE IF EXISTS `#{hash[:database]}`")
      client.query("CREATE DATABASE `#{hash[:database]}`")
      client.close
    end

    def reload_schemas
      load Rails.root.join("db", "schema.rb")
      load Rails.root.join("db", "test_dump_schema.rb")
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { DatabaseSetup.prepare_test_databases! }
  config.after(:each) { DatabaseSetup.reset_users_tables! }
end
