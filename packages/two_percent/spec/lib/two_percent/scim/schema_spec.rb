# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::Scim::Schema do
  describe "constants" do
    it "defines CORE_USER_SCHEMA" do
      expect(described_class::CORE_USER_SCHEMA).to eq("urn:ietf:params:scim:schemas:core:2.0:User")
    end

    it "defines CORE_GROUP_SCHEMA" do
      expect(described_class::CORE_GROUP_SCHEMA).to eq("urn:ietf:params:scim:schemas:core:2.0:Group")
    end

    it "defines EXTENSION_SCHEMA" do
      expect(described_class::EXTENSION_SCHEMA).to eq("urn:ietf:params:scim:schemas:extension:authservice:2.0:User")
    end

    it "defines CORE_USER_ATTRIBUTES" do
      expect(described_class::CORE_USER_ATTRIBUTES).to include("id", "userName", "displayName", "emails", "active")
    end

    it "defines CORE_GROUP_ATTRIBUTES" do
      expect(described_class::CORE_GROUP_ATTRIBUTES).to include("id", "displayName", "members")
    end

    it "defines EXTENSION_USER_ATTRIBUTES" do
      expect(described_class::EXTENSION_USER_ATTRIBUTES).to include("department", "territory", "role", "mfaRequired")
    end
  end

  describe ".validate_user" do
    let(:valid_user) do
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => "user-123",
        "externalId" => "ext-123",
        "userName" => "john.doe@example.com",
        "displayName" => "John Doe",
        "emails" => [
          { "value" => "john@example.com", "type" => "work", "primary" => true }
        ],
        "active" => true
      }
    end

    context "with require_id: true (default)" do
      it "validates a complete user" do
        expect {
          described_class.validate_user(valid_user)
        }.not_to raise_error
      end

      it "returns normalized user data with core and extensions" do
        result = described_class.validate_user(valid_user)

        expect(result).to have_key(:core)
        expect(result).to have_key(:extensions)
        expect(result[:core]["id"]).to eq("user-123")
        expect(result[:core]["userName"]).to eq("john.doe@example.com")
      end

      it "raises error when id is missing" do
        invalid_user = valid_user.dup.tap { |u| u.delete("id") }

        expect {
          described_class.validate_user(invalid_user)
        }.to raise_error(ArgumentError, "Missing required attributes: id")
      end

      it "raises error when externalId is missing" do
        invalid_user = valid_user.dup.tap { |u| u.delete("externalId") }

        expect {
          described_class.validate_user(invalid_user)
        }.to raise_error(ArgumentError, "Missing required attributes: externalId")
      end
    end

    context "with require_id: false" do
      it "allows user without id (for creation)" do
        user_without_id = valid_user.dup.tap { |u| u.delete("id") }

        expect {
          described_class.validate_user(user_without_id, require_id: false)
        }.not_to raise_error
      end

      it "still requires externalId" do
        user_without_external_id = valid_user.dup.tap { |u| u.delete("externalId") }

        expect {
          described_class.validate_user(user_without_external_id, require_id: false)
        }.to raise_error(ArgumentError, "Missing required attributes: externalId")
      end
    end

    context "schemas validation" do
      it "raises error when schemas attribute is missing" do
        user_without_schemas = valid_user.dup.tap { |u| u.delete("schemas") }

        expect {
          described_class.validate_user(user_without_schemas)
        }.to raise_error(ArgumentError, "schemas attribute is required")
      end

      it "raises error when schemas is empty array" do
        user_with_empty_schemas = valid_user.merge("schemas" => [])

        expect {
          described_class.validate_user(user_with_empty_schemas)
        }.to raise_error(ArgumentError, "schemas attribute is required")
      end

      it "accepts extension schemas" do
        user_with_extension = valid_user.merge(
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User", "urn:ietf:params:scim:schemas:extension:authservice:2.0:User"]
        )

        expect {
          described_class.validate_user(user_with_extension)
        }.not_to raise_error
      end
    end

    context "attribute type validation" do
      it "validates name structure" do
        user_with_name = valid_user.merge(
          "name" => {
            "givenName" => "John",
            "familyName" => "Doe",
            "middleName" => "M"
          }
        )

        expect {
          described_class.validate_user(user_with_name)
        }.not_to raise_error
      end

      it "raises error for invalid name attributes" do
        user_with_invalid_name = valid_user.merge(
          "name" => { "invalidKey" => "value" }
        )

        expect {
          described_class.validate_user(user_with_invalid_name)
        }.to raise_error(ArgumentError, /Invalid name attributes/)
      end

      it "validates emails multi-valued attribute" do
        user_with_emails = valid_user.merge(
          "emails" => [
            { "value" => "john@example.com", "type" => "work" },
            { "value" => "john.doe@personal.com", "type" => "home" }
          ]
        )

        expect {
          described_class.validate_user(user_with_emails)
        }.not_to raise_error
      end

      it "raises error when emails missing required keys" do
        user_with_invalid_emails = valid_user.merge(
          "emails" => [{ "value" => "john@example.com" }] # Missing 'type'
        )

        expect {
          described_class.validate_user(user_with_invalid_emails)
        }.to raise_error(ArgumentError, /Multi-valued attribute item 0 missing: type/)
      end

      it "validates phoneNumbers multi-valued attribute" do
        user_with_phones = valid_user.merge(
          "phoneNumbers" => [
            { "value" => "555-1234", "type" => "mobile" }
          ]
        )

        expect {
          described_class.validate_user(user_with_phones)
        }.not_to raise_error
      end

      it "raises error when phoneNumbers missing required keys" do
        user_with_invalid_phones = valid_user.merge(
          "phoneNumbers" => [{ "value" => "555-1234" }] # Missing 'type'
        )

        expect {
          described_class.validate_user(user_with_invalid_phones)
        }.to raise_error(ArgumentError, /Multi-valued attribute item 0 missing: type/)
      end

      it "validates addresses multi-valued attribute" do
        user_with_addresses = valid_user.merge(
          "addresses" => [
            { "type" => "work", "streetAddress" => "123 Main St", "locality" => "Springfield" }
          ]
        )

        expect {
          described_class.validate_user(user_with_addresses)
        }.not_to raise_error
      end

      it "raises error when addresses missing type" do
        user_with_invalid_addresses = valid_user.merge(
          "addresses" => [{ "streetAddress" => "123 Main St" }] # Missing 'type'
        )

        expect {
          described_class.validate_user(user_with_invalid_addresses)
        }.to raise_error(ArgumentError, /Multi-valued attribute item 0 missing: type/)
      end

      it "validates photos multi-valued attribute" do
        user_with_photos = valid_user.merge(
          "photos" => [
            { "value" => "https://example.com/photo.jpg", "type" => "photo" }
          ]
        )

        expect {
          described_class.validate_user(user_with_photos)
        }.not_to raise_error
      end

      it "raises error when multi-valued item is not a hash" do
        user_with_invalid_emails = valid_user.merge(
          "emails" => ["string-instead-of-hash"]
        )

        expect {
          described_class.validate_user(user_with_invalid_emails)
        }.to raise_error(ArgumentError, /Multi-valued attribute item 0 must be an object/)
      end
    end

    context "normalization" do
      it "extracts core attributes" do
        result = described_class.validate_user(valid_user)

        expect(result[:core]).to include("id", "externalId", "userName", "displayName")
        expect(result[:core]["id"]).to eq("user-123")
      end

      it "extracts extension attributes" do
        user_with_extension = valid_user.merge(
          "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
            "department" => "Engineering",
            "role" => "Developer"
          }
        )

        result = described_class.validate_user(user_with_extension)

        expect(result[:extensions]).to have_key("urn:ietf:params:scim:schemas:extension:authservice:2.0:User")
        expect(result[:extensions]["urn:ietf:params:scim:schemas:extension:authservice:2.0:User"]["department"]).to eq("Engineering")
      end

      it "returns empty extensions hash when no extensions present" do
        result = described_class.validate_user(valid_user)

        expect(result[:extensions]).to be_a(Hash)
        expect(result[:extensions]).to be_empty
      end
    end
  end

  describe ".validate_group" do
    let(:valid_group) do
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        "id" => "group-123",
        "displayName" => "Engineering",
        "members" => []
      }
    end

    context "with require_id: true (default)" do
      it "validates a complete group" do
        expect {
          described_class.validate_group(valid_group)
        }.not_to raise_error
      end

      it "returns normalized group data" do
        result = described_class.validate_group(valid_group)

        expect(result).to have_key(:core)
        expect(result).to have_key(:extensions)
        expect(result[:core]["id"]).to eq("group-123")
        expect(result[:core]["displayName"]).to eq("Engineering")
      end

      it "raises error when id is missing" do
        invalid_group = valid_group.dup.tap { |g| g.delete("id") }

        expect {
          described_class.validate_group(invalid_group)
        }.to raise_error(ArgumentError, "Missing required attributes: id")
      end

      it "raises error when displayName is missing" do
        invalid_group = valid_group.dup.tap { |g| g.delete("displayName") }

        expect {
          described_class.validate_group(invalid_group)
        }.to raise_error(ArgumentError, /Missing required attributes.*displayName/)
      end
    end

    context "with require_id: false" do
      it "allows group without id (for creation)" do
        group_without_id = valid_group.dup.tap { |g| g.delete("id") }

        expect {
          described_class.validate_group(group_without_id, require_id: false)
        }.not_to raise_error
      end

      it "still requires displayName" do
        group_without_display_name = valid_group.dup.tap { |g| g.delete("displayName") }

        expect {
          described_class.validate_group(group_without_display_name, require_id: false)
        }.to raise_error(ArgumentError, "Missing required attributes: displayName")
      end
    end

    context "schemas validation" do
      it "raises error when schemas attribute is missing" do
        group_without_schemas = valid_group.dup.tap { |g| g.delete("schemas") }

        expect {
          described_class.validate_group(group_without_schemas)
        }.to raise_error(ArgumentError, "schemas attribute is required")
      end

      it "raises error when schemas is empty array" do
        group_with_empty_schemas = valid_group.merge("schemas" => [])

        expect {
          described_class.validate_group(group_with_empty_schemas)
        }.to raise_error(ArgumentError, "schemas attribute is required")
      end
    end

    context "normalization" do
      it "extracts core attributes" do
        result = described_class.validate_group(valid_group)

        expect(result[:core]).to include("id", "displayName")
        expect(result[:core]["id"]).to eq("group-123")
      end

      it "handles group with members" do
        group_with_members = valid_group.merge(
          "members" => [
            { "value" => "user-123", "display" => "John Doe" }
          ]
        )

        result = described_class.validate_group(group_with_members)

        expect(result[:core]["members"]).to be_an(Array)
        expect(result[:core]["members"].size).to eq(1)
      end
    end
  end

  describe ".normalize_user" do
    it "separates core and extension attributes" do
      user_hash = {
        "id" => "user-123",
        "userName" => "john@example.com",
        "displayName" => "John Doe",
        "customAttribute" => "custom",
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
          "department" => "Engineering"
        }
      }

      result = described_class.normalize_user(user_hash)

      expect(result[:core]).to include("id", "userName", "displayName")
      expect(result[:core]).not_to have_key("customAttribute")
      expect(result[:extensions]).to have_key("urn:ietf:params:scim:schemas:extension:authservice:2.0:User")
    end
  end

  describe ".normalize_group" do
    it "separates core and extension attributes" do
      group_hash = {
        "id" => "group-123",
        "displayName" => "Engineering",
        "customAttribute" => "custom"
      }

      result = described_class.normalize_group(group_hash)

      expect(result[:core]).to include("id", "displayName")
      expect(result[:core]).not_to have_key("customAttribute")
    end
  end

  describe ".extract_core_attributes" do
    it "extracts only allowed attributes" do
      scim_hash = {
        "id" => "123",
        "userName" => "john@example.com",
        "customAttr" => "custom",
        "anotherAttr" => "another"
      }

      result = described_class.extract_core_attributes(scim_hash, %w[id userName])

      expect(result).to eq({ "id" => "123", "userName" => "john@example.com" })
    end
  end

  describe ".extract_extensions" do
    it "extracts attributes starting with extension schema URN" do
      scim_hash = {
        "id" => "123",
        "userName" => "john@example.com",
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => { "department" => "Engineering" },
        "urn:ietf:params:scim:schemas:extension:custom:1.0:User" => { "customField" => "value" }
      }

      result = described_class.extract_extensions(scim_hash)

      expect(result.size).to eq(2)
      expect(result).to have_key("urn:ietf:params:scim:schemas:extension:authservice:2.0:User")
      expect(result).to have_key("urn:ietf:params:scim:schemas:extension:custom:1.0:User")
    end

    it "returns empty hash when no extensions present" do
      scim_hash = {
        "id" => "123",
        "userName" => "john@example.com"
      }

      result = described_class.extract_extensions(scim_hash)

      expect(result).to eq({})
    end
  end

  describe ".validate_schemas_present" do
    it "raises error when schemas is nil" do
      expect {
        described_class.validate_schemas_present({})
      }.to raise_error(ArgumentError, "schemas attribute is required")
    end

    it "raises error when schemas is empty" do
      expect {
        described_class.validate_schemas_present({ "schemas" => [] })
      }.to raise_error(ArgumentError, "schemas attribute is required")
    end

    it "does not raise error when schemas has values" do
      expect {
        described_class.validate_schemas_present({ "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"] })
      }.not_to raise_error
    end
  end

  describe ".validate_required_attributes" do
    it "raises error when required attribute is missing" do
      expect {
        described_class.validate_required_attributes({ "id" => "123" }, %w[id externalId])
      }.to raise_error(ArgumentError, "Missing required attributes: externalId")
    end

    it "raises error when multiple required attributes are missing" do
      expect {
        described_class.validate_required_attributes({}, %w[id externalId userName])
      }.to raise_error(ArgumentError, /Missing required attributes/)
    end

    it "does not raise error when all required attributes present" do
      expect {
        described_class.validate_required_attributes(
          { "id" => "123", "externalId" => "ext-123" },
          %w[id externalId]
        )
      }.not_to raise_error
    end
  end

  describe ".validate_name_structure" do
    it "validates valid name structure" do
      name = {
        "formatted" => "Mr. John M Doe",
        "familyName" => "Doe",
        "givenName" => "John",
        "middleName" => "M",
        "honorificPrefix" => "Mr.",
        "honorificSuffix" => "Jr."
      }

      expect {
        described_class.validate_name_structure(name)
      }.not_to raise_error
    end

    it "raises error for invalid name keys" do
      name = {
        "givenName" => "John",
        "invalidKey" => "invalid"
      }

      expect {
        described_class.validate_name_structure(name)
      }.to raise_error(ArgumentError, /Invalid name attributes: invalidKey/)
    end

    it "does not validate non-hash name" do
      expect {
        described_class.validate_name_structure("string-name")
      }.not_to raise_error
    end
  end

  describe ".validate_multi_valued" do
    it "validates array of valid objects" do
      emails = [
        { "value" => "john@example.com", "type" => "work" },
        { "value" => "john.doe@personal.com", "type" => "home" }
      ]

      expect {
        described_class.validate_multi_valued(emails, %w[value type])
      }.not_to raise_error
    end

    it "raises error when item is not a hash" do
      emails = ["string-instead-of-hash"]

      expect {
        described_class.validate_multi_valued(emails, %w[value type])
      }.to raise_error(ArgumentError, /Multi-valued attribute item 0 must be an object/)
    end

    it "raises error when required key is missing" do
      emails = [{ "value" => "john@example.com" }] # Missing 'type'

      expect {
        described_class.validate_multi_valued(emails, %w[value type])
      }.to raise_error(ArgumentError, /Multi-valued attribute item 0 missing: type/)
    end

    it "does not validate non-array input" do
      expect {
        described_class.validate_multi_valued("not-an-array", %w[value type])
      }.not_to raise_error
    end
  end
end
