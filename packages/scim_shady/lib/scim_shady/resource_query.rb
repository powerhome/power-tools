# frozen_string_literal: true

module ScimShady
  module ResourceQuery
    extend ActiveSupport::Concern

    class_methods do
      def find(path_or_id)
        ScimShady.client.get(path: "#{resource_path}/#{path_or_id}", model: self)
          .tap(&:clear_changes_information)
      end

      def query(**kwargs)
        QueryBuilder.new(model: self, **kwargs)
      end

      def all(**kwargs)
        query(**kwargs).all
      end
    end
  end
end
