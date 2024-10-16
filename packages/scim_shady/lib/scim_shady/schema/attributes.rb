# frozen_string_literal: true

module ScimShady
  module Schema
    class Attributes < Hash
      def initialize(attribute_list)
        super

        attribute_list.each do |attr|
          self[attr["name"]] = Attribute.new(attr)
        end
      end
    end
  end
end
