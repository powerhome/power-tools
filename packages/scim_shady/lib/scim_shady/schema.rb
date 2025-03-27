# frozen_string_literal: true

module ScimShady
  module Schema
    autoload :Attribute, "scim_shady/schema/attribute"
    autoload :Attributes, "scim_shady/schema/attributes"
    autoload :ComplexType, "scim_shady/schema/complex_type"
    autoload :MetaType, "scim_shady/schema/meta_type"
    autoload :Resource, "scim_shady/schema/resource"

    def self.all
      @all ||= ScimShady.client.get(path: "Schemas", list: Resource)
    end

    def self.[](id)
      all.find { _1.id.eql?(id) } || raise(ScimShady::UnknownSchema, "Unknown schema #{id.inspect}")
    end
  end
end
