# frozen_string_literal: true

RSpec.describe ScimShady::PatchOp do
  let(:object) { User.new }
  subject { ScimShady::PatchOp.new(object) }

  it "generates operations for user changes in the default schema" do
    object.display_name = "Mr John Doe"
    object.title = "Vice President of Nothing"

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations" => [
        {
          "op" => "replace",
          "path" => "displayName",
          "value" => "Mr John Doe"
        },
        {
          "op" => "replace",
          "path" => "title",
          "value" => "Vice President of Nothing"
        }
      ]
    )
  end

  it "generates operations for user changes in the a non-default schema" do
    object.mfa_required = false

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations" => [
        {
          "op" => "replace",
          "path" => "urn:ietf:params:scim:schemas:extension:service:2.0:User:mfaRequired",
          "value" => false
        }
      ]
    )
  end

  it "generates operations for complex attributes" do
    object.name = {
      formatted: "John Doe"
    }

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
      "Operations" => [
        {
          "op" => "replace",
          "path" => "name",
          "value" => {
            "formatted" => "John Doe"
          }
        }
      ]
    )
  end
end
