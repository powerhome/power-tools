# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Writes spatial indexes to schema.rb as activerecord-mysql2rgeo-adapter
    # does: <tt>using: :gist, type: :spatial</tt>. Prepended to
    # MySQL::SchemaDumper; other indexes are left to Rails.
    module SchemaDumper # :nodoc:
    private

      # MySQL reports a key prefix length (32) for spatial indexes, but rejects
      # one when creating them, so it is left out.
      # https://github.com/rails/rails/blob/v7.2.4/activerecord/lib/active_record/schema_dumper.rb#L260
      def index_parts(index)
        parts = super
        return parts unless index.type == :spatial

        parts = parts.grep_v(/\Alength: /)
        parts.insert(parts.index("type: :spatial"), "using: :gist") if index.using.nil?
        parts
      end
    end
  end
end
