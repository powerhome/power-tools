# frozen_string_literal: true

RSpec.describe ScimShady::Schema do
  it "loads the schemas from the client and caches them" do
    expect(ScimShady.client).to_not receive(:get).with(path: "Schemas")

    # See Get-Schemas.json
    expect(ScimShady::Schema.all.count).to eql 4
  end

  describe ".[id]" do
    it "loads the given schema" do
      schema = ScimShady::Schema["urn:ietf:params:scim:schemas:core:2.0:User"]

      expect(schema).to be_a ScimShady::Schema::Resource
      expect(schema.id).to eql "urn:ietf:params:scim:schemas:core:2.0:User"
      expect(schema.name).to eql "User"
    end

    it "raises an error when the schema id does not exist" do
      expect do
        ScimShady::Schema["what?"]
      end.to raise_error ScimShady::UnknownSchema, "Unknown schema \"what?\""
    end
  end
end
