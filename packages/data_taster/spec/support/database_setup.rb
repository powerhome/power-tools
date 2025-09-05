# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    load Rails.root.join("db", "schema.rb")
    load Rails.root.join("db", "test_dump_schema.rb")
  end

  config.after(:each) do
    include DatabaseHelper

    source_db_client.query("TRUNCATE TABLE users")
    dump_db_client.query("TRUNCATE TABLE users")
  end
end
