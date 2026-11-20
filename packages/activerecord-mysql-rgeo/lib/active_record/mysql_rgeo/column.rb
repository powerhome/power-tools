# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Lets every MySQL column answer +spatial?+, as every column of
    # activerecord-mysql2rgeo-adapter did. Included in MySQL::Column;
    # SpatialColumn answers true.
    module Column
      def spatial?
        false
      end
    end
  end
end
