# frozen_string_literal: true

require "rake"

RSpec.configure do |config|
  config.before(:suite) do
    # Create the databases
    Rails.application.load_tasks
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke

    # Load the schema
    load Rails.root.join("db", "schema.rb")
    load Rails.root.join("db", "test_dump_schema.rb")
  end

  config.after(:each) do
    source_db_client.query("TRUNCATE TABLE users")
    source_db_client.query("TRUNCATE TABLE cars")
    source_db_client.query("TRUNCATE TABLE dogs")
    dump_db_client.query("TRUNCATE TABLE users")
    dump_db_client.query("TRUNCATE TABLE cars")
    dump_db_client.query("TRUNCATE TABLE dogs")
  end
end
