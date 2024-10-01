# frozen_string_literal: true

RSpec.describe ScimShady::Schema::Attribute do
  subject { ScimShady::Schema::Attribute.new({"name" => "name", "type" => "string"}) }

  describe "#name" do
    it "is cast to a symbol" do
      expect(subject.name).to eql :name
    end
  end

  describe "#type" do
    it "is cast to a symbol" do
      expect(subject.type).to eql :string
    end

    it "is a ComplexType when of a 'complext' type" do
      attribute = ScimShady::Schema::Attribute.new({
        "name" => "name",
        "type" => "complex",
        "subAttributes" => []
      })

      expect(attribute.type).to be_a ScimShady::Schema::ComplexType
    end

    it "is a multi ComplexType when of a multiValued 'complext' type" do
      attribute = ScimShady::Schema::Attribute.new({
        "name" => "name",
        "type" => "complex",
        "subAttributes" => [],
        "multiValued" => true
      })

      expect(attribute.type).to be_a ScimShady::Schema::ComplexType
      expect(attribute.type).to be_multi
    end
  end

  describe "#mutability" do
    it "is writeable when it is readWrite" do
      attribute = ScimShady::Schema::Attribute.new("name" => "name", "type" => "string", "mutability" => "readWrite")

      expect(attribute.mutability).to eql "readWrite"
      expect(attribute).to be_write
      expect(attribute).to be_read
      expect(attribute).to_not be_immutable
    end

    it "is writeable when it is writeOnly" do
      attribute = ScimShady::Schema::Attribute.new("name" => "name", "type" => "string", "mutability" => "writeOnly")

      expect(attribute.mutability).to eql "writeOnly"
      expect(attribute).to be_write
      expect(attribute).to_not be_read
      expect(attribute).to_not be_immutable
    end

    it "is writeable when it is readWrite" do
      attribute = ScimShady::Schema::Attribute.new("name" => "name", "type" => "string", "mutability" => "readOnly")

      expect(attribute.mutability).to eql "readOnly"
      expect(attribute).to_not be_write
      expect(attribute).to be_read
      expect(attribute).to_not be_immutable
    end

    it "is writeable when it is readWrite" do
      attribute = ScimShady::Schema::Attribute.new("name" => "name", "type" => "string", "mutability" => "immutable")

      expect(attribute.mutability).to eql "immutable"
      expect(attribute).to_not be_write
      expect(attribute).to be_read
      expect(attribute).to be_immutable
    end
  end
end
