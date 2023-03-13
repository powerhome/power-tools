# frozen_string_literal: true

module NitroHistory
  module Graphql
    class HistoriesQuery < NitroGraphql::BaseQuery
      description "History entry for the given source"

      type [::NitroHistory::Graphql::HistoryType], null: false
      argument :source_type, String
      argument :source_id, ID
      argument :encrypted, Boolean
      argument :in_natural_order, Boolean, required: false

      def resolve(source_type:, source_id:, encrypted:, in_natural_order: false)
        object = Object.const_get(source_type).find(source_id)
        ::NitroHistory.for(object, encrypted: encrypted, in_natural_order: in_natural_order)
      end
    end
  end
end
