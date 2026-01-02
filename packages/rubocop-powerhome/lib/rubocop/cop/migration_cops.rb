# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      require_relative "migration/rename_column"
      require_relative "migration/rename_table"
    end
  end
end
