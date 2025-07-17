# frozen_string_literal: true

# Helper methods to get database configurations, accounting for changes between rails versions
module DatabaseHelper
  def test_database_config
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "primary").configuration_hash
  rescue ArgumentError
    ActiveRecord::Base.configurations.configs_for(env_name: "test", spec_name: "primary").config
  end

  def test_dump_database_config
    ActiveRecord::Base.configurations.configs_for(env_name: "test_dump", name: "primary").configuration_hash
  rescue ArgumentError
    ActiveRecord::Base.configurations.configs_for(env_name: "test_dump", spec_name: "primary").config
  end
end

RSpec.configure do |config|
  config.include DatabaseHelper
end
