# frozen_string_literal: true

# Preloaded before Active Record's test files: loads the gem the way an
# application would, then makes sure the suite's databases exist.
#
# Set REGRESSION_BASELINE=1 to run the suite without the gem, to tell failures
# caused by the gem apart from ones caused by the environment.

require "active_record"
require "active_support/configuration_file"
require "activerecord-mysql-rgeo" unless ENV["REGRESSION_BASELINE"] == "1"
require_relative "excludes"

adapter = ENV.fetch("ARCONN")
server = ActiveSupport::ConfigurationFile.parse(ENV.fetch("ARCONFIG")).dig("connections", adapter, "arunit")

ActiveRecord::Base.establish_connection(server.merge("adapter" => adapter))
ActiveRecord::Base.with_connection do |connection|
  %w[activerecord_unittest activerecord_unittest2].each do |database|
    connection.execute("CREATE DATABASE IF NOT EXISTS #{connection.quote_table_name(database)}")
  end
end
ActiveRecord::Base.remove_connection
