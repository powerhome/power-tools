# frozen_string_literal: true

module ScimShady
  class PatchOp < Struct.new(:object)
    class Operation < Struct.new(:attribute, :schema, :value)
      def as_json(...)
        {"op" => "replace", "path" => path, "value" => value}.as_json(...)
      end

      def path
        schema.default? ? attribute : "#{schema.id}:#{attribute}"
      end
    end

    def operations
      object.changes.map do |attribute, (_, value)|
        Operation.new(attribute, schema_for(attribute), value)
      end
    end

    def as_json(...)
      {
        "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        "Operations" => operations
      }.as_json(...)
    end

    private

    def schema_for(attribute)
      object.class.schemas.find { _1.attributes.key?(attribute) }
    end
  end
end
