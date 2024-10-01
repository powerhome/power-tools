# frozen_string_literal: true

RSpec.describe ScimShady::ScimJson do
  let(:object) { User.new }
  subject { ScimShady::ScimJson.new(object) }

  it "generates a SCIM Json with all provided data for the default schema" do
    object.display_name = "Mr John Doe"
    object.title = "Vice President of Nothing"

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:service:2.0:User"],
      "externalId" => nil,
      "userName" => nil,
      "name" => nil,
      "displayName" => "Mr John Doe",
      "nickName" => nil,
      "profileUrl" => nil,
      "title" => "Vice President of Nothing",
      "userType" => nil,
      "preferredLanguage" => nil,
      "locale" => nil,
      "timezone" => nil,
      "active" => nil,
      "password" => nil,
      "emails" => nil,
      "phoneNumbers" => nil,
      "ims" => nil,
      "photos" => nil,
      "addresses" => nil,
      "entitlements" => nil,
      "roles" => nil,
      "x509Certificates" => nil,
      "urn:ietf:params:scim:schemas:extension:service:2.0:User" => {
        "mfaRequired" => nil
      }
    )
  end

  it "generates a SCIM Json with all provided data for the non-default schema" do
    object.mfa_required = true

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:service:2.0:User"],
      "externalId" => nil,
      "userName" => nil,
      "name" => nil,
      "displayName" => nil,
      "nickName" => nil,
      "profileUrl" => nil,
      "title" => nil,
      "userType" => nil,
      "preferredLanguage" => nil,
      "locale" => nil,
      "timezone" => nil,
      "active" => nil,
      "password" => nil,
      "emails" => nil,
      "phoneNumbers" => nil,
      "ims" => nil,
      "photos" => nil,
      "addresses" => nil,
      "entitlements" => nil,
      "roles" => nil,
      "x509Certificates" => nil,
      "urn:ietf:params:scim:schemas:extension:service:2.0:User" => {
        "mfaRequired" => true
      }
    )
  end

  it "generates a SCIM Json for complex attributes" do
    object.name = {
      formatted: "John Doe"
    }

    expect(subject.as_json).to eql(
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:service:2.0:User"],
      "externalId" => nil,
      "userName" => nil,
      "name" => {
        "formatted" => "John Doe"
      },
      "displayName" => nil,
      "nickName" => nil,
      "profileUrl" => nil,
      "title" => nil,
      "userType" => nil,
      "preferredLanguage" => nil,
      "locale" => nil,
      "timezone" => nil,
      "active" => nil,
      "password" => nil,
      "emails" => nil,
      "phoneNumbers" => nil,
      "ims" => nil,
      "photos" => nil,
      "addresses" => nil,
      "entitlements" => nil,
      "roles" => nil,
      "x509Certificates" => nil,
      "urn:ietf:params:scim:schemas:extension:service:2.0:User" => {
        "mfaRequired" => nil
      }
    )
  end
end
