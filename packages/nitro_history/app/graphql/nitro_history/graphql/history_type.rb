# frozen_string_literal: true

module NitroHistory
  module Graphql
    class HistoryType < NitroGraphql::Types::BaseObject
      graphql_name "History"
      description "Nitro History type"

      field :id, ID, null: false
      field :created_at, NitroGraphql::Types::Date, null: false
      field :note, String

      field :created_by, ::Directory::Graphql::EmployeeType
      def created_by
        return unless object.user_id

        NitroGraphql::Loaders::ActiveRecord.for(::Directory::Employee)
                                           .load(object.user_id)
      end

      # For some reason the `activity` is mapped to a helper method in HistoryHelper
      # Manually mapping the attribute fixed the issue
      field :activity, String, null: false
      def activity # rubocop:disable Rails/Delegate
        object.activity
      end
    end
  end
end
