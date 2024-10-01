# frozen_string_literal: true

RSpec.describe ScimShady::Schema::Attributes do
  let(:user_schema) { fixture_json("Get-Schemas.json")["Resources"].first }
  subject { ScimShady::Schema::Attributes.new(user_schema["attributes"]) }

  it "indexes attributes by name" do
    expect(subject.keys).to match_array [
      "userName",
      "name",
      "displayName",
      "nickName",
      "profileUrl",
      "title",
      "userType",
      "preferredLanguage",
      "locale",
      "timezone",
      "active",
      "password",
      "emails",
      "phoneNumbers",
      "ims",
      "photos",
      "addresses",
      "groups",
      "entitlements",
      "roles",
      "x509Certificates"
    ]
  end
end
