# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Trino
      module ReadOnly
        WRITE_METHODS = %i[
          insert
          update
          delete
          exec_insert
          exec_update
          exec_delete
          insert_fixture
          insert_fixtures_set
          truncate
          truncate_tables
          begin_db_transaction
          commit_db_transaction
          rollback_db_transaction
          exec_rollback_db_transaction
          begin_isolated_db_transaction
          create_savepoint
          exec_rollback_to_savepoint
          release_savepoint
          create_table
          drop_table
          create_join_table
          drop_join_table
          rename_table
          add_column
          remove_column
          change_column
          change_column_default
          change_column_null
          rename_column
          add_index
          remove_index
          rename_index
          add_foreign_key
          remove_foreign_key
          add_reference
          remove_reference
          add_belongs_to
          remove_belongs_to
          add_check_constraint
          remove_check_constraint
        ].freeze

        WRITE_METHODS.each do |method|
          define_method(method) do |*_args, **_kwargs, &_block|
            raise Stagecoach::ReadOnlyError,
                  "stagecoach: #{method} is not supported by the Trino adapter " \
                  "(stagecoach is read-only)"
          end
        end
      end
    end
  end
end
