# frozen_string_literal: true

module ScimShady
  module Schema
    class Resource
      DEFAULT = [
        "urn:ietf:params:scim:schemas:core:2.0:User",
        "urn:ietf:params:scim:schemas:core:2.0:Group"
      ]

      attr_reader :id, :name, :description, :meta, :attributes

      def initialize(attrs)
        @id = attrs["id"]
        @name = attrs["name"]
        @description = attrs["description"]
        @attributes = Attributes.new(attrs["attributes"])
      end

      def default?
        DEFAULT.include?(id)
      end
    end
  end
end
