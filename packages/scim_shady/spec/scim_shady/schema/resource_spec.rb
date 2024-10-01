# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScimShady::Schema::Resource do
  let(:user_schema) { fixture_json("Get-Schemas.json")["Resources"].first }
  subject { ScimShady::Schema::Resource.new(user_schema) }

  it do
    is_expected.to have_attributes(
      id: "urn:ietf:params:scim:schemas:core:2.0:User",
      name: "User",
      description: "Represents a User"
    )
  end

  it "maps the resource attributes" do
    expect(subject.attributes).to be_a ScimShady::Schema::Attributes
  end
end
