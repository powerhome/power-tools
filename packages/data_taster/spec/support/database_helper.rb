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

private

  def db_config
    DatabaseHelper.db_config_instance
  end

module_function

  def db_config_instance
    @db_config_instance ||= DBConfig.new
  end
end
