# frozen_string_literal: true

module ScimShady
  class ScimJson < Struct.new(:object)
    def as_json(...)
      schema_ids = object.class.schemas.map(&:id)
      object.class.schemas.reduce({schemas: schema_ids, externalId: object.external_id}) do |scim, schema|
        result = as_schema_scim(schema)
        schema.default? ? scim.merge(result) : scim.merge(schema.id => result)
      end.as_json(...)
    end

    private

    def as_schema_scim(schema)
      schema.attributes.values.reduce({}) do |scim, attribute|
        next scim unless attribute.write?
        scim.merge(attribute.name => object.public_send(attribute.name))
      end
    end
  end
end
