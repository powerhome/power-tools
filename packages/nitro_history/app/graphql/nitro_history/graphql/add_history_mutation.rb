# frozen_string_literal: true

module NitroHistory
  module Graphql
    class AddHistoryMutation < NitroGraphql::BaseQuery
      description "Add a history entry for the given source"

      type ::NitroHistory::Graphql::HistoryType, null: false
      argument :source_type, String
      argument :source_id, ID
      argument :activity, String
      argument :note, String
      argument :encrypted, Boolean, required: false

      def resolve(source_type:, source_id:, activity:, note:, encrypted: false)
        object = Object.const_get(source_type).find(source_id)
        ::NitroHistory.record!(
          object,
          activity,
          nil,
          context[:current_user].id,
          note,
          encrypted: encrypted
        )
      end
    end
  end
end
