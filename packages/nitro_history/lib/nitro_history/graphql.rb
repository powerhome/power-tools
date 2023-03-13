# frozen_string_literal: true

module NitroHistory
  module Graphql
    extend ::NitroGraphql::Schema::Partial

    queries do
      field :histories, resolver: ::NitroHistory::Graphql::HistoriesQuery
    end

    mutations do
      field :add_history, resolver: ::NitroHistory::Graphql::AddHistoryMutation
    end
  end
end
