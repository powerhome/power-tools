# frozen_string_literal: true

# Connects the specs to a MySQL server through the driver named by DB_ADAPTER
# (trilogy or mysql2). Connection settings come from the MYSQL_* variables and
# default to the MySQL server preinstalled on GitHub's Ubuntu runners.
module TestDatabase
  ADAPTERS = %w[trilogy mysql2].freeze

module_function

  def adapter
    name = ENV.fetch("DB_ADAPTER", "trilogy")
    return name if ADAPTERS.include?(name)

    raise ArgumentError, "DB_ADAPTER must be one of #{ADAPTERS.join(', ')}, got #{name.inspect}"
  end

  def config
    {
      adapter: adapter,
      host: ENV.fetch("MYSQL_HOST", "127.0.0.1"),
      port: Integer(ENV.fetch("MYSQL_PORT", "3306")),
      username: ENV.fetch("MYSQL_USER", "root"),
      password: ENV.fetch("MYSQL_PASSWORD", "root"),
      database: ENV.fetch("MYSQL_DATABASE", "activerecord_mysql_rgeo_test"),
    }
  end

  def connect!
    ActiveRecord::Base.establish_connection(config.except(:database))
    ActiveRecord::Base.with_connection do |connection|
      connection.execute("CREATE DATABASE IF NOT EXISTS #{connection.quote_table_name(config[:database])}")
    end
    ActiveRecord::Base.establish_connection(config)
  end
end
