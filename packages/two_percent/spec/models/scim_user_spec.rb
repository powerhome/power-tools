# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::ScimUser, type: :model do
  describe "validations" do
    subject(:scim_user) { build_scim_user }

    it { is_expected.to validate_presence_of(:scim_id) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:scim_data) }

    it { is_expected.to validate_uniqueness_of(:scim_id) }

    describe "scim_id data type" do
      it "stores scim_id as string, not integer" do
        user = create_scim_user(scim_id: "12345")
        expect(user.reload.scim_id).to be_a(String)
        expect(user.scim_id).to eq("12345")
      end

      it "handles numeric-looking scim_ids correctly" do
        user = create_scim_user(scim_id: "999999")
        expect(user.reload.scim_id).to eq("999999")
        expect(user.scim_id).not_to eq(999_999)
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:scim_group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:scim_groups).through(:scim_group_memberships) }

    it "destroys memberships when user is destroyed" do
      user = create_scim_user
      group = create_scim_group
      membership = TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group)

      expect { user.destroy }.to change { TwoPercent::ScimGroupMembership.count }.by(-1)
      expect(TwoPercent::ScimGroupMembership.exists?(membership.id)).to be false
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active users" do
        active_user = create_scim_user(active: true)
        inactive_user = create_scim_user(active: false)

        expect(described_class.active).to include(active_user)
        expect(described_class.active).not_to include(inactive_user)
      end
    end
  end

  describe ".upsert_from_scim" do
    let(:scim_hash) do
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => "user-123",
        "externalId" => "ext-123",
        "userName" => "john.doe",
        "displayName" => "John Doe",
        "emails" => [
          { "value" => "john@example.com", "type" => "work", "primary" => true },
        ],
        "active" => true,
      }
    end

    context "when user does not exist" do
      it "creates a new user" do
        expect do
          described_class.upsert_from_scim(scim_hash)
        end.to change { described_class.count }.by(1)
      end

      it "sets all attributes correctly" do
        user = described_class.upsert_from_scim(scim_hash)

        expect(user.scim_id).to eq("user-123")
        expect(user.external_id).to eq("ext-123")
        expect(user.user_name).to eq("john.doe")
        expect(user.display_name).to eq("John Doe")
        expect(user.email).to eq("john@example.com")
        expect(user.active).to be true
      end

      it "stores full SCIM data in scim_data column" do
        user = described_class.upsert_from_scim(scim_hash)

        expect(user.scim_data).to be_a(Hash)
        expect(user.scim_data["id"]).to eq("user-123")
        expect(user.scim_data["userName"]).to eq("john.doe")
      end

      it "persists to database" do
        user = described_class.upsert_from_scim(scim_hash)

        expect(user).to be_persisted
        expect(user.id).not_to be_nil
      end
    end

    context "when user already exists" do
      let!(:existing_user) { create_scim_user(scim_id: "user-123", display_name: "Old Name") }

      it "does not create a new user" do
        expect do
          described_class.upsert_from_scim(scim_hash)
        end.not_to(change { described_class.count })
      end

      it "updates existing user attributes" do
        user = described_class.upsert_from_scim(scim_hash)

        expect(user.id).to eq(existing_user.id)
        expect(user.display_name).to eq("John Doe")
        expect(user.display_name).not_to eq("Old Name")
      end

      it "updates scim_data" do
        user = described_class.upsert_from_scim(scim_hash)

        expect(user.scim_data["displayName"]).to eq("John Doe")
      end
    end

    context "with correlation_id" do
      it "stores the correlation_id when provided" do
        user = described_class.upsert_from_scim(scim_hash, correlation_id: "abc-123")

        expect(user.correlation_id).to eq("abc-123")
      end

      it "allows nil correlation_id" do
        user = described_class.upsert_from_scim(scim_hash, correlation_id: nil)

        expect(user.correlation_id).to be_nil
      end
    end

    context "with extension schemas" do
      let(:scim_hash_with_extension) do
        scim_hash.merge(
          "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
            "customAttribute" => "customValue",
          }
        )
      end

      it "stores extension data in scim_data" do
        user = described_class.upsert_from_scim(scim_hash_with_extension)

        extension_data = user.scim_data["urn:ietf:params:scim:schemas:extension:authservice:2.0:User"]
        expect(extension_data).to be_present
        expect(extension_data["customAttribute"]).to eq("customValue")
      end
    end

    context "with invalid SCIM data" do
      it "validates SCIM schema before persisting" do
        invalid_hash = { "id" => "user-123" } # Missing required fields

        expect do
          described_class.upsert_from_scim(invalid_hash)
        end.to raise_error(ArgumentError, /schemas attribute is required/)
      end
    end
  end

  describe ".find_by_scim_id" do
    it "finds user by scim_id" do
      user = create_scim_user(scim_id: "user-456")

      found_user = described_class.find_by_scim_id("user-456")
      expect(found_user).to eq(user)
    end

    it "returns nil when user not found" do
      expect(described_class.find_by_scim_id("nonexistent")).to be_nil
    end
  end

  describe ".exists_by_scim_id?" do
    it "returns true when user exists" do
      create_scim_user(scim_id: "user-789")

      expect(described_class.exists_by_scim_id?("user-789")).to be true
    end

    it "returns false when user does not exist" do
      expect(described_class.exists_by_scim_id?("nonexistent")).to be false
    end
  end

  describe ".destroy_by_scim_id" do
    context "when user exists" do
      let!(:user) { create_scim_user(scim_id: "user-999") }

      it "destroys the user" do
        expect do
          described_class.destroy_by_scim_id("user-999")
        end.to change { described_class.count }.by(-1)
      end

      it "returns the destroyed user" do
        result = described_class.destroy_by_scim_id("user-999")
        expect(result).to be_a(described_class)
        expect(result.scim_id).to eq("user-999")
        expect(result).to be_destroyed
      end
    end

    context "when user does not exist" do
      it "returns nil" do
        result = described_class.destroy_by_scim_id("nonexistent")
        expect(result).to be_nil
      end

      it "does not raise an error" do
        expect do
          described_class.destroy_by_scim_id("nonexistent")
        end.not_to raise_error
      end
    end
  end

  describe "#to_domain_attributes" do
    let(:user) { create_scim_user_with_groups }

    it "returns a hash with domain attributes" do
      attributes = user.to_domain_attributes

      expect(attributes).to be_a(Hash)
      expect(attributes).to include(
        :scim_id,
        :external_id,
        :display_name,
        :email,
        :active
      )
    end

    it "includes group memberships" do
      attributes = user.to_domain_attributes

      expect(attributes[:groups]).to be_an(Array)
      expect(attributes[:groups].first).to include(:scim_id, :display_name, :resource_type)
    end
  end

  describe "#to_scim_representation" do
    let(:user) { create_scim_user }

    it "returns RFC 7644 compliant SCIM User resource" do
      scim_repr = user.to_scim_representation

      expect(scim_repr).to be_a(Hash)
      expect(scim_repr["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:User")
      expect(scim_repr["id"]).to eq(user.scim_id)
    end

    it "includes meta information" do
      scim_repr = user.to_scim_representation

      expect(scim_repr["meta"]).to be_present
      expect(scim_repr["meta"]["resourceType"]).to eq("User")
    end

    it "includes core attributes" do
      scim_repr = user.to_scim_representation

      expect(scim_repr).to include("userName", "displayName", "emails", "active")
    end

    it "includes extension attributes when present" do
      user_with_extension = create_scim_user_with_extension
      scim_repr = user_with_extension.to_scim_representation

      expect(scim_repr.keys).to include(match(/^urn:ietf:params:scim:schemas:extension:/))
    end
  end

  describe "#scim_attribute" do
    let(:scim_data) do
      {
        "userName" => "john.doe",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe",
        },
        "emails" => [
          { "value" => "john@example.com", "type" => "work" },
        ],
      }
    end
    let(:user) { create_scim_user(scim_data: scim_data) }

    it "returns attribute by dot-notation path" do
      expect(user.scim_attribute("userName")).to eq("john.doe")
    end

    it "handles nested paths" do
      expect(user.scim_attribute("name.givenName")).to eq("John")
      expect(user.scim_attribute("name.familyName")).to eq("Doe")
    end

    it "returns nil for missing paths" do
      expect(user.scim_attribute("nonexistent.path")).to be_nil
    end

    it "handles array paths" do
      expect(user.scim_attribute("emails")).to be_an(Array)
    end
  end

  describe "#extension_attributes" do
    let(:scim_data) do
      {
        "userName" => "john.doe",
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
          "department" => "Engineering",
        },
        "urn:ietf:params:scim:schemas:extension:custom:1.0:User" => {
          "badge" => "12345",
        },
      }
    end
    let(:user) { create_scim_user(scim_data: scim_data) }

    context "without schema URN" do
      it "returns all extension schemas" do
        extensions = user.extension_attributes

        expect(extensions).to be_a(Hash)
        expect(extensions.keys).to all(start_with("urn:ietf:params:scim:schemas:extension:"))
        expect(extensions.size).to eq(2)
      end

      it "does not include core attributes" do
        extensions = user.extension_attributes

        expect(extensions).not_to have_key("userName")
      end
    end

    context "with specific schema URN" do
      it "returns only that extension schema" do
        extension = user.extension_attributes("urn:ietf:params:scim:schemas:extension:authservice:2.0:User")

        expect(extension).to eq({ "department" => "Engineering" })
      end

      it "returns empty hash when extension not present" do
        extension = user.extension_attributes("urn:ietf:params:scim:schemas:extension:nonexistent:1.0:User")

        expect(extension).to eq({})
      end
    end

    context "when no extensions present" do
      let(:user_without_extensions) { create_scim_user }

      it "returns empty hash" do
        extensions = user_without_extensions.extension_attributes

        expect(extensions).to eq({})
      end
    end
  end

  describe "#to_scim_representation with dynamic groups (RFC 7643 read-only)" do
    let!(:user) { create_scim_user(scim_id: "user-789") }
    let!(:group1) do
      create_scim_group(
        scim_id: "group-111",
        display_name: "Engineering",
        resource_type: "Departments"
      )
    end
    let!(:group2) do
      create_scim_group(
        scim_id: "group-222",
        display_name: "Admins",
        resource_type: "Groups"
      )
    end

    context "when user has group memberships" do
      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group1)
        TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group2)
        # Reload with scim_groups association preloaded (like ScimController does)
        user.reload
        user.scim_groups.reload
      end

      it "includes groups array in SCIM representation" do
        scim_repr = user.to_scim_representation

        expect(scim_repr["groups"]).to be_an(Array)
        expect(scim_repr["groups"].size).to eq(2)
      end

      it "includes SCIM-compliant group attributes (value, display, $ref, type)" do
        scim_repr = user.to_scim_representation
        groups = scim_repr["groups"]

        group_values = groups.map { |g| g["value"] }
        expect(group_values).to contain_exactly("group-111", "group-222")

        # Verify all groups have required/recommended attributes
        groups.each do |group|
          expect(group).to have_key("value")
          expect(group).to have_key("display")
          expect(group).to have_key("$ref")
          expect(group).to have_key("type")
        end
      end

      it "builds groups dynamically from join table, not from scim_data" do
        # Verify groups are NOT stored in scim_data
        expect(user.scim_data).not_to have_key("groups")

        # But they appear in SCIM representation
        scim_repr = user.to_scim_representation
        expect(scim_repr["groups"]).to be_present
        expect(scim_repr["groups"].size).to eq(2)
      end

      it "includes correct display names for groups" do
        scim_repr = user.to_scim_representation
        groups = scim_repr["groups"]

        display_names = groups.map { |g| g["display"] }
        expect(display_names).to contain_exactly("Engineering", "Admins")
      end

      it "includes $ref URIs for groups" do
        scim_repr = user.to_scim_representation
        groups = scim_repr["groups"]

        refs = groups.map { |g| g["$ref"] }
        expect(refs).to contain_exactly("Departments/group-111", "Groups/group-222")
      end

      it "includes resource type for groups" do
        scim_repr = user.to_scim_representation
        groups = scim_repr["groups"]

        types = groups.map { |g| g["type"] }
        expect(types).to contain_exactly("Departments", "Groups")
      end
    end

    context "when user has no group memberships" do
      it "returns empty groups array or omits groups key" do
        user.reload # Ensure no memberships loaded
        scim_repr = user.to_scim_representation

        # Either empty array or key is not present
        groups = scim_repr["groups"]
        expect(groups).to be_nil.or(eq([]))
      end
    end

    context "when group is added via Group.members (not User.groups)" do
      it "reflects in user's groups array dynamically" do
        # Initially no groups
        user.scim_groups.reload
        scim_repr_before = user.to_scim_representation
        expect(scim_repr_before["groups"] || []).to be_empty

        # Add membership via join table
        TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group1)
        user.reload
        user.scim_groups.reload

        # Now appears in groups
        scim_repr_after = user.to_scim_representation
        expect(scim_repr_after["groups"]).to be_an(Array)
        expect(scim_repr_after["groups"].size).to eq(1)
        expect(scim_repr_after["groups"].first["value"]).to eq("group-111")
      end
    end
  end

  # Test helpers
  def build_scim_user(attributes = {})
    default_attributes = {
      scim_id: "user-#{SecureRandom.hex(4)}",
      external_id: "ext-#{SecureRandom.hex(4)}",
      user_name: "test.user",
      display_name: "Test User",
      email: "test@example.com",
      active: true,
      scim_data: {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => "test",
        "userName" => "test.user",
        "displayName" => "Test User",
        "emails" => [{ "value" => "test@example.com", "type" => "work", "primary" => true }],
        "active" => true,
      },
    }
    described_class.new(default_attributes.merge(attributes))
  end

  def create_scim_user(attributes = {})
    build_scim_user(attributes).tap(&:save!)
  end

  def create_scim_group(attributes = {})
    scim_id = attributes[:scim_id] || "group-#{SecureRandom.hex(4)}"
    external_id = attributes[:external_id] || "ext-#{SecureRandom.hex(4)}"
    display_name = attributes[:display_name] || "Test Group"
    resource_type = attributes[:resource_type] || "Groups"

    default_scim_data = {
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
      "id" => scim_id,
      "externalId" => external_id,
      "displayName" => display_name,
      "members" => [],
    }

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      display_name: display_name,
      resource_type: resource_type,
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimGroup.create!(full_attributes)
  end

  def create_scim_user_with_groups
    user = create_scim_user
    group1 = create_scim_group(display_name: "Developers", resource_type: "Departments")
    group2 = create_scim_group(display_name: "Managers", resource_type: "Roles")

    TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group1)
    TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group2)

    user.reload
  end

  def create_scim_user_with_extension
    scim_data_with_ext = {
      "schemas" => [
        "urn:ietf:params:scim:schemas:core:2.0:User",
        "urn:ietf:params:scim:schemas:extension:authservice:2.0:User",
      ],
      "id" => "user-ext",
      "userName" => "john",
      "displayName" => "John Ext",
      "emails" => [{ "value" => "john@example.com", "primary" => true }],
      "urn:ietf:params:scim:schemas:extension:authservice:2.0:User" => {
        "customField" => "customValue",
      },
    }
    create_scim_user(
      user_name: "john",
      display_name: "John Ext",
      email: "john@example.com",
      scim_data: scim_data_with_ext
    )
  end
end
