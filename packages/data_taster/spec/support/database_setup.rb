# frozen_string_literal: true

require "mysql2"

RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
      hash = db_config.configuration_hash
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

    ActiveRecord::Base.connection_handler.clear_all_connections!

    load Rails.root.join("db", "schema.rb")
    load Rails.root.join("db", "test_dump_schema.rb")
  end

  config.after(:each) do
    include DatabaseHelper

    source_db_client.query("TRUNCATE TABLE users")
    begin
      dump_db_client.query("TRUNCATE TABLE users")
    rescue Mysql2::Error
      load Rails.root.join("db", "test_dump_schema.rb")
      dump_db_client.query("TRUNCATE TABLE users")
    end
  end
end
