# frozen_string_literal: true

module RuboCop
  module Cop
    module GraphQL
      require_relative "graphql/base_cop"
      require_relative "graphql/default_null_true"
      require_relative "graphql/default_required_true"
      require_relative "graphql/field_type_in_block"
      require_relative "graphql/root_types_in_block"
    end
  end
end
