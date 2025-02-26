# frozen_string_literal: true

module DWConnector
  class RepositoryFactory
    class << self
      def create(table_name:, type: :trino, conditions: nil, config: {})
        repository_class = repository_for(type)
        repository_class.new(table_name, conditions, config)
      end

    private

      def repository_for(type)
        case type
        when :trino
          Adapters::TrinoRepository
        else
          raise ArgumentError, "Unsupported repository type: #{type}. Available types: #{available_types.join(', ')}"
        end
      end

      def available_types
        [:trino]
      end
    end
  end
end
