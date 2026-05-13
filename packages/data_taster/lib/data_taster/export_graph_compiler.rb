# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/ParameterLists
module DataTaster
  # Expands top-level +data_taster_export_graphs+ in export YAML into flat
  # +table_name => WHERE fragment+ entries for {Collection}. Removes the reserved
  # key. Explicit table keys in the file win over generated ones.
  class ExportGraphCompiler
    RESERVED_KEY = "data_taster_export_graphs"
    DEFAULT_ORDER = "id DESC"
    DEFAULT_LIMIT = 200

    class Error < StandardError; end
    class UnsupportedAssociation < Error; end

    class << self
      def merge_into!(hash)
        graphs = hash.delete(RESERVED_KEY)
        return hash unless graphs.is_a?(Hash)

        compiled = {}
        graphs.each_value do |spec|
          compile_named_graph!(compiled, spec)
        end

        hash.replace(compiled.merge(hash))
      end

    private

      def compile_named_graph!(tables, spec)
        spec = stringify_keys(spec)
        anchor = spec["anchor"]
        raise Error, "data_taster graph missing anchor" unless anchor.is_a?(Hash)

        anchor = stringify_keys(anchor)
        model_name = anchor.fetch("model")
        anchor_class = constantize_anchor(model_name)
        where_sql = anchor.fetch("where_sql")
        order = normalized_order(anchor["order"])
        limit = limit_value(anchor["limit"])

        includes = Array(spec["includes"])
        raise Error, "data_taster graph includes must be a non-empty list" if includes.empty?

        tables[anchor_class.table_name] =
          anchor_owning_rows_clause(anchor_class, where_sql, order, limit)

        includes.each do |name|
          add_include!(tables, anchor_class, where_sql, order, limit, name.to_sym)
        end
      end

      def normalized_order(value)
        s = value.to_s.strip
        s.empty? ? DEFAULT_ORDER : s
      end

      def add_include!(tables, anchor_class, where_sql, order, limit, assoc_name)
        reflection = anchor_class.reflect_on_association(assoc_name)
        raise Error, "Unknown association #{assoc_name.inspect} on #{anchor_class.name}" unless reflection

        if reflection.polymorphic?
          log_skip_association("polymorphic", anchor_class.name, assoc_name)
          return
        end

        if %i[has_many has_one].include?(reflection.macro) && reflection.options[:as].present?
          log_skip_association("polymorphic-inverse", anchor_class.name, assoc_name)
          return
        end

        case reflection.macro
        when :has_many, :has_one
          if reflection.options[:through]
            compile_has_many_through!(tables, anchor_class, reflection, where_sql, order, limit)
          else
            compile_has_many_or_has_one!(tables, reflection, where_sql, order, limit)
          end
        when :belongs_to
          compile_belongs_to!(tables, reflection, anchor_class, where_sql, order, limit)
        else
          msg = "Unsupported macro #{reflection.macro} for #{assoc_name} on #{anchor_class.name}"
          raise UnsupportedAssociation, msg
        end
      end

      def log_skip_association(kind, model_name, assoc_name)
        DataTaster.logger.info(
          "[DataTaster::ExportGraphCompiler] Skipping #{kind} association #{assoc_name.inspect} on #{model_name}"
        )
      end

      def anchor_owning_rows_clause(anchor_class, where_sql, order, limit)
        anchor_table = anchor_class.table_name
        anchor_pk = anchor_class.primary_key.to_s
        if anchor_pk.include?(",")
          raise UnsupportedAssociation, "Composite primary key not supported for #{anchor_class.name}"
        end

        inner = anchor_inner_select(anchor_table, anchor_pk, where_sql, order, limit)
        subquery = wrapped_anchor_column_subquery(inner, anchor_pk, "data_taster_anchor_ids")
        "`#{quote_ident_part(anchor_pk)}` IN (#{subquery})"
      end

      def compile_has_many_or_has_one!(tables, reflection, where_sql, order, limit)
        child = reflection.klass
        fk = reflection.foreign_key.to_s
        anchor_table = reflection.active_record.table_name
        anchor_pk = reflection.active_record.primary_key.to_s
        if anchor_pk.include?(",")
          raise UnsupportedAssociation, "Composite primary key not supported for #{reflection.active_record.name}"
        end

        inner = anchor_inner_select(anchor_table, anchor_pk, where_sql, order, limit)
        anchor_sq = wrapped_anchor_column_subquery(inner, anchor_pk, "data_taster_anchor_ids")
        tables[child.table_name] = "`#{quote_ident_part(fk)}` IN (#{anchor_sq})"
      end

      def compile_belongs_to!(tables, reflection, anchor_class, where_sql, order, limit)
        parent_table = reflection.klass.table_name
        parent_pk = association_primary_key_column(reflection)
        fk = reflection.foreign_key.to_s
        anchor_table = anchor_class.table_name

        lim = limit_sql_fragment(limit)
        inner = <<~SQL.squish
          SELECT `#{quote_ident_part(fk)}` FROM #{source_database_name}.`#{quote_ident_part(anchor_table)}`
          WHERE (#{where_sql}) ORDER BY #{order} #{lim}
        SQL
        wrapped = wrapped_anchor_column_subquery(inner, fk, "data_taster_anchor_fks")
        sql = "`#{quote_ident_part(parent_pk)}` IN (#{wrapped})"
        tables[parent_table] = sql
      end

      def compile_has_many_through!(tables, anchor_class, reflection, where_sql, order, limit)
        parts = through_association_parts(anchor_class, reflection)
        inner = anchor_inner_select(
          parts.fetch(:anchor_table),
          parts.fetch(:anchor_pk),
          where_sql,
          order,
          limit
        )
        anchor_sq = wrapped_anchor_column_subquery(inner, parts.fetch(:anchor_pk), "data_taster_anchor_ids")
        join_fk = parts.fetch(:join_fk_to_anchor)
        join_table = parts.fetch(:join_table)
        tables[join_table] = "`#{quote_ident_part(join_fk)}` IN (#{anchor_sq})"

        target_table = parts.fetch(:target_table)
        target_pk = parts.fetch(:target_pk)
        target_fk = parts.fetch(:target_fk)
        tables[target_table] = <<~SQL.squish
          `#{quote_ident_part(target_pk)}` IN (
            SELECT `#{quote_ident_part(target_fk)}` FROM #{source_database_name}.`#{quote_ident_part(join_table)}`
            WHERE `#{quote_ident_part(join_fk)}` IN (#{anchor_sq})
          )
        SQL
      end

      def through_association_parts(anchor_class, reflection)
        through = reflection.through_reflection
        join_table = through.klass.table_name
        join_fk_to_anchor = through.foreign_key.to_s

        source = reflection.source_reflection
        if source.options[:through]
          raise UnsupportedAssociation,
                "Multi-level has_many :through is not supported (#{reflection.name} on #{anchor_class.name})"
        end

        target_table = source.klass.table_name
        target_pk = source.klass.primary_key.to_s
        target_fk = source.foreign_key.to_s
        if target_pk.blank? || target_pk.include?(",")
          raise UnsupportedAssociation, "Composite primary key not supported for #{source.klass.name}"
        end

        {
          anchor_table: anchor_class.table_name,
          anchor_pk: anchor_class.primary_key.to_s,
          join_table: join_table,
          join_fk_to_anchor: join_fk_to_anchor,
          target_table: target_table,
          target_pk: target_pk,
          target_fk: target_fk,
        }
      end

      def anchor_inner_select(anchor_table, anchor_pk, where_sql, order, limit)
        lim = limit_sql_fragment(limit)
        <<~SQL.squish
          SELECT `#{quote_ident_part(anchor_pk)}` FROM #{source_database_name}.`#{quote_ident_part(anchor_table)}`
          WHERE (#{where_sql}) ORDER BY #{order} #{lim}
        SQL
      end

      # MySQL rejects +IN (SELECT ... ORDER BY ... LIMIT ...)+ on many versions; wrapping the inner
      # select as a derived table is the standard workaround.
      def wrapped_anchor_column_subquery(inner_select_sql, column_name, derived_table_alias)
        qc = quote_ident_part(column_name)
        qa = quote_ident_part(derived_table_alias)
        <<~SQL.squish
          SELECT `#{qc}` FROM (#{inner_select_sql.strip}) AS `#{qa}`
        SQL
      end

      def limit_value(raw)
        return DEFAULT_LIMIT if raw.nil?

        raw.to_i
      end

      def limit_sql_fragment(limit)
        return "" if limit == 0

        "LIMIT #{Integer(limit)}"
      end

      def association_primary_key_column(reflection)
        pk = reflection.association_primary_key
        pk = pk.first if pk.is_a?(Array)
        pk = pk.to_s
        raise UnsupportedAssociation, "Composite association primary key not supported" if pk.include?(",") || pk.blank?

        pk
      end

      def constantize_anchor(model_name)
        class_name = model_name.to_s
        unless anchor_model_allowed?(class_name)
          raise Error, "Anchor model not allowed by graph_anchor_allowlist: #{class_name.inspect}"
        end

        class_name.constantize
      end

      def anchor_model_allowed?(class_name)
        list = DataTaster.config.graph_anchor_allowlist
        return true if list.nil?

        Array(list).any? { |prefix| class_name.start_with?(prefix.to_s) }
      end

      def stringify_keys(obj)
        return obj unless obj.is_a?(Hash)

        obj.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      end

      def quote_ident_part(str)
        str.to_s.gsub("`", "``")
      end

      def source_database_name
        db = DataTaster.config.source_client&.query_options&.[](:database)
        if db.nil? || db.to_s.empty?
          raise Error,
                "Cannot resolve source database for export graphs; set DataTaster.config " \
                "with source_client.query_options[:database]"
        end

        db.to_s
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/ParameterLists
