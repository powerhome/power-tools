# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Raised when activerecord-mysql2rgeo-adapter, which this gem replaces, is
    # loaded in the same application.
    class ConflictingGemError < ActiveRecordError
      UPSTREAM_ADAPTER = :Mysql2RgeoAdapter

      def self.check!
        return unless ConnectionAdapters.const_defined?(UPSTREAM_ADAPTER, false)

        raise self, "activerecord-mysql-rgeo replaces activerecord-mysql2rgeo-adapter, and they can't be " \
                    "loaded together. Remove activerecord-mysql2rgeo-adapter from your Gemfile, and change " \
                    "adapter: mysql2rgeo to trilogy or mysql2 in database.yml."
      end
    end
  end
end
