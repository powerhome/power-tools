# frozen_string_literal: true

module DataTaster
  # Picks the adapter that gives a database client the Mysql2::Client interface DataTaster relies on
  module Adapters
    autoload :Trilogy, "data_taster/adapters/trilogy"

    def self.wrap(client)
      if defined?(::Trilogy) && client.is_a?(::Trilogy)
        Trilogy.new(client)
      else
        client
      end
    end
  end
end
