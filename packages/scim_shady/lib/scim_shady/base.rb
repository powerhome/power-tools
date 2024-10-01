# frozen_string_literal: true

module ScimShady
  class Base
    include ResourceQuery
    include SchemaAttributes
    include Persistence
    include ActiveModel::Serializers::JSON

    def initialize(attributes = {})
      super()

      assign_attributes(attributes)
    end

    def self.resource_path
      name.pluralize
    end

    def resource_path
      self.class.resource_path
    end
  end
end
