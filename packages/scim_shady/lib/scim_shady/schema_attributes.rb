# frozen_string_literal: true

module ScimShady
  module SchemaAttributes
    extend ActiveSupport::Concern
    include ActiveModel::Attributes
    include ActiveModel::AttributeAssignment
    include ActiveModel::Dirty

    included do
      attribute :id, :integer
      attribute :externalId, :string
      alias_attribute :external_id, :externalId
      attribute :meta, Schema::MetaType.new
      attribute :schemas

      class_attribute :schemas, instance_accessor: false

      private

      def _assign_attribute(key, value)
        if self.class.schemas.map(&:id).include?(key)
          assign_attributes(value)
        else
          super
        end
      end
    end

    class_methods do
      def schema(*ids)
        self.schemas = Array(ids).map { Schema[_1] }
          .each do |schema|
          schema.attributes.each_value do |attr|
            miltiform_attribute(attr.name.to_s, attr.type)
          end
        end
      end

      def miltiform_attribute(name, ...)
        attribute(name, ...)
        alias_attribute(name.underscore, name) unless name.underscore.eql?(name)
      end
    end
  end
end
