# frozen_string_literal: true

module DWConduit
  class RepositoryFactory
    class << self
      def repositories
        @repositories ||= {}
      end

      def register(type, repository_class)
        repositories[type.to_sym] = repository_class
      end

      def create(table_name:, type: :trino, conditions: nil, config: {})
        repository_class = repository_for(type)
        repository_class.new(table_name, conditions, config)
      end

    private

      def repository_for(type)
        type = type.to_sym
        repositories[type] || raise(
          ArgumentError,
          "Unsupported repository type: #{type}. Available types: #{repositories.keys.join(', ')}"
        )
      end
    end
  end
end
