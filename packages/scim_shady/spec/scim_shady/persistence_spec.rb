# frozen_string_literal: true

require "spec_helper"

RSpec.describe ScimShady::Persistence do
  describe "#persisted?" do
    subject { User.new }

    it "is persisted when the id exists" do
      expect(subject).to_not be_persisted

      subject.id = 123

      expect(subject).to be_persisted
    end
  end

  describe "#save" do
    subject { User.new }

    context "when creating" do
      it "clears the changes" do
        subject.externalId = "john.doe"
        subject.displayName = "John Doe"
        subject.title = "Developer"
        subject.name = {
          familyName: "Doe",
          givenName: "John",
          formatted: "John Doe"
        }
        subject.phone_numbers = [
          {
            primary: true,
            type: "mobile",
            value: "+5531777778888",
            display: "Mobile Number"
          }
        ]

        ScimShady.client.mock(
          method: :Post,
          path: "Users",
          body: {
            "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:service:2.0:User"],
            "externalId" => "john.doe",
            "userName" => nil,
            "name" => {
              "familyName" => "Doe",
              "givenName" => "John",
              "formatted" => "John Doe"
            },
            "displayName" => "John Doe",
            "nickName" => nil,
            "profileUrl" => nil,
            "title" => "Developer",
            "userType" => nil,
            "preferredLanguage" => nil,
            "locale" => nil,
            "timezone" => nil,
            "active" => nil,
            "password" => nil,
            "emails" => nil,
            "phoneNumbers" => [
              {
                "primary" => true,
                "type" => "mobile",
                "value" => "+5531777778888",
                "display" => "Mobile Number"
              }
            ],
            "ims" => nil,
            "photos" => nil,
            "addresses" => nil,
            "entitlements" => nil,
            "roles" => nil,
            "x509Certificates" => nil,
            "urn:ietf:params:scim:schemas:extension:service:2.0:User" => {
              "mfaRequired" => nil
            }
          },
          fixture: "user-resource.json"
        )

        subject.save

        expect(subject).to_not be_changed
      end

      it "applies changes from the response" do
        subject.externalId = "john.doe"

        ScimShady.client.mock(
          method: :Post,
          path: "Users",
          body: {
            "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:service:2.0:User"],
            "externalId" => "john.doe",
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
              "mfaRequired" => nil
            }
          },
          fixture: "user-resource.json",
          response: {
            "name" => {
              "formatted" => "John Doe"
            }
          }
        )

        subject.save

        expect(subject.name.formatted).to eql("John Doe")
      end
    end

    context "when updating" do
      before do
        ScimShady.client.mock(
          method: :Get,
          path: "Users/123",
          fixture: "user-resource.json"
        )
      end
      subject { User.find(123) }

      it "clears the changes" do
        subject.display_name = "Mr John Doe"
        subject.title = "Vice President of Nothing"

        ScimShady.client.mock(
          method: :Patch,
          path: "Users/123",
          body: {
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
          },
          response: {
            "displayName" => "Mr John Doe",
            "title" => "Vice President of Nothing"
          }
        )

        subject.save

        expect(subject).to_not be_changed
      end

      it "applies modified attributes from response" do
        subject.display_name = "Mr John Doe"
        subject.title = "Vice President of Nothing"

        ScimShady.client.mock(
          method: :Patch,
          path: "Users/123",
          body: {
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
          },
          response: {
            "displayName" => "Something else"
          }
        )

        subject.save

        expect(subject.displayName).to eql "Something else"
      end
    end
  end
end
