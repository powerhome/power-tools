# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Do not rename tables. It will cause down time in your application and is unsafe for pt-online-schema-change.
      # Instead:
      #
      # 1. Create a new table
      # 2. Backfill and write to the new table
      # 3. Drop the old table
      #
      # @example
      #   # bad
      #   class RenameUsersToAccouts < ActiveRecord::Migration[7.0]
      #     def change
      #       rename_table :users, :accounts
      #     end
      #   end
      #
      #   # good
      #   class AddAccounts < ActiveRecord::Migration[7.0]
      #     def change
      #       create_table :accounts do |t|
      #         t.string :name, null: false
      #       end
      #     end
      #   end
      #
      #   class RemoveUsers < ActiveRecord::Migration[7.0]
      #     def change
      #       remove_table :users, if_exists: true
      #     end
      #   end
      class RenameTable < RuboCop::Cop::Base
        MSG = "Do not rename tables. It will cause down time in your application " \
              "and is unsafe for pt-online-schema-change."

        def on_send(node)
          return unless rename_table?(node)

          add_offense(node)
        end
        alias on_csend on_send

        def_node_matcher :rename_table?, <<~PATTERN
          (send
            nil?
            :rename_table
            ...
          )
        PATTERN
      end
    end
  end
end
