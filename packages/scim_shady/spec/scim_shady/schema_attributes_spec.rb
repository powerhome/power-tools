# frozen_string_literal: true

RSpec::Matchers.define :define_attribute do |name, type:, aliased: false|
  match do |model|
    expect(model.attribute_aliases[aliased]).to eql(name) if aliased
    expect(model.attribute_types[name]).to be_a(type)
  end
end

require "spec_helper"

RSpec.describe ScimShady::SchemaAttributes do
  subject { User }

  describe "default attributes" do
    it { is_expected.to define_attribute("id", type: ActiveModel::Type::Integer) }
    it { is_expected.to define_attribute("externalId", aliased: "external_id", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("meta", type: ScimShady::Schema::MetaType) }
    it { is_expected.to define_attribute("schemas", type: ActiveModel::Type::Value) }
  end

  describe "attribute definition" do
    it { is_expected.to define_attribute("displayName", aliased: "display_name", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("name", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("x509Certificates", aliased: "x509_certificates", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("userName", aliased: "user_name", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("nickName", aliased: "nick_name", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("profileUrl", aliased: "profile_url", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("title", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("userType", aliased: "user_type", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("preferredLanguage", aliased: "preferred_language", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("locale", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("timezone", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("active", type: ActiveModel::Type::Boolean) }
    it { is_expected.to define_attribute("password", type: ActiveModel::Type::String) }
    it { is_expected.to define_attribute("emails", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("phoneNumbers", aliased: "phone_numbers", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("ims", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("photos", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("addresses", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("groups", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("entitlements", type: ScimShady::Schema::ComplexType) }
    it { is_expected.to define_attribute("roles", type: ScimShady::Schema::ComplexType) }
  end

  describe "attribute assignment" do
    let(:raw_object) { fixture_json("user-resource.json") }
    let(:object) { User.new(raw_object) }

    it "allows initializing with the schema attributes" do
      expect(object.displayName).to eql "John Doe"
    end

    it "allows initializing complex attributes" do
      expect(object.groups[0].value).to eql "2"
      expect(object.groups[0].display).to eql "Information Technology"
      expect(object.groups[1].value).to eql "3"
      expect(object.groups[1].display).to eql "VP Of AOE"
      expect(object.groups[2].value).to eql "1"
      expect(object.groups[2].display).to eql "New York"
    end

    it "allows id and externalId" do
      expect(object.id).to eql 123
      expect(object.externalId).to eql "john.doe"
      expect(object.external_id).to eql "john.doe"
    end

    it "includes metadata" do
      expect(object.meta).to have_attributes(
        location: "https://example.com/api/scim/Users/123966",
        created: "2022-11-29T11:02:55-05:00",
        lastModified: "2024-03-20T10:49:50-04:00",
        resourceType: "UserResource"
      )
    end

    it "includes the schemas" do
      expect(object.schemas).to match_array [
        "urn:ietf:params:scim:schemas:core:2.0:User"
      ]
    end

    it "allows setting extension attributes" do
      expect(object.mfaRequired).to be true
      expect(object.department).to eql "Technology"
    end
  end
end
