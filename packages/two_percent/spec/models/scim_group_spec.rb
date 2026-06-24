# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::ScimGroup, type: :model do
  describe "validations" do
    subject(:scim_group) { build_scim_group }

    it { is_expected.to validate_presence_of(:scim_id) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:display_name) }
    it { is_expected.to validate_presence_of(:resource_type) }
    it { is_expected.to validate_presence_of(:scim_data) }

    it { is_expected.to validate_uniqueness_of(:scim_id) }
  end

  describe "associations" do
    it { is_expected.to have_many(:scim_group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:scim_users).through(:scim_group_memberships) }

    it "destroys memberships when group is destroyed" do
      group = create_scim_group
      user = create_scim_user
      membership = TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group)

      expect { group.destroy }.to change { TwoPercent::ScimGroupMembership.count }.by(-1)
      expect(TwoPercent::ScimGroupMembership.exists?(membership.id)).to be false
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active groups" do
        active_group = create_scim_group(active: true)
        inactive_group = create_scim_group(active: false)

        expect(described_class.active).to include(active_group)
        expect(described_class.active).not_to include(inactive_group)
      end
    end

    describe ".by_resource_type" do
      it "returns groups filtered by resource type" do
        departments = create_scim_group(resource_type: "Departments")
        roles = create_scim_group(resource_type: "Roles")
        titles = create_scim_group(resource_type: "Titles")

        expect(described_class.by_resource_type("Departments")).to include(departments)
        expect(described_class.by_resource_type("Departments")).not_to include(roles, titles)
      end
    end
  end

  describe ".upsert_from_scim" do
    let(:resource_type) { "Departments" }
    let(:scim_hash) do
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        "id" => "group-123",
        "externalId" => "ext-123",
        "displayName" => "Engineering",
        "members" => [],
      }
    end

    context "when group does not exist" do
      it "creates a new group" do
        expect do
          described_class.upsert_from_scim(resource_type, scim_hash)
        end.to change { described_class.count }.by(1)
      end

      it "sets all attributes correctly" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.scim_id).to eq("group-123")
        expect(group.external_id).to eq("ext-123")
        expect(group.display_name).to eq("Engineering")
        expect(group.resource_type).to eq("Departments")
        expect(group.active).to be true
      end

      it "stores full SCIM data in scim_data column" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.scim_data).to be_a(Hash)
        expect(group.scim_data["id"]).to eq("group-123")
        expect(group.scim_data["displayName"]).to eq("Engineering")
      end

      it "persists to database" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group).to be_persisted
        expect(group.id).not_to be_nil
      end
    end

    context "when group already exists" do
      let!(:existing_group) { create_scim_group(scim_id: "group-123", display_name: "Old Name") }

      it "does not create a new group" do
        expect do
          described_class.upsert_from_scim(resource_type, scim_hash)
        end.not_to(change { described_class.count })
      end

      it "updates existing group attributes" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.id).to eq(existing_group.id)
        expect(group.display_name).to eq("Engineering")
        expect(group.display_name).not_to eq("Old Name")
      end

      it "updates scim_data" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.scim_data["displayName"]).to eq("Engineering")
      end
    end

    context "with members array" do
      let!(:user1) { create_scim_user(scim_id: "user-1") }
      let!(:user2) { create_scim_user(scim_id: "user-2") }

      let(:scim_hash_with_members) do
        scim_hash.merge(
          "members" => [
            { "value" => "user-1", "display" => "User One" },
            { "value" => "user-2", "display" => "User Two" },
          ]
        )
      end

      it "syncs members when present" do
        group = described_class.upsert_from_scim(resource_type, scim_hash_with_members)

        expect(group.scim_users.count).to eq(2)
        expect(group.scim_users).to include(user1, user2)
      end

      it "does not sync members when array is empty" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.scim_users.count).to eq(0)
      end
    end

    context "with correlation_id" do
      it "stores the correlation_id when provided" do
        group = described_class.upsert_from_scim(resource_type, scim_hash, correlation_id: "abc-123")

        expect(group.correlation_id).to eq("abc-123")
      end

      it "allows nil correlation_id" do
        group = described_class.upsert_from_scim(resource_type, scim_hash, correlation_id: nil)

        expect(group.correlation_id).to be_nil
      end
    end

    context "with extension schemas containing active flag" do
      let(:scim_hash_with_active_false) do
        scim_hash.merge(
          "urn:ietf:params:scim:schemas:extension:authservice:2.0:Group" => {
            "active" => false,
          }
        )
      end

      it "sets active to false when extension has active: false" do
        group = described_class.upsert_from_scim(resource_type, scim_hash_with_active_false)

        expect(group.active).to be false
      end

      it "defaults active to true when extension missing" do
        group = described_class.upsert_from_scim(resource_type, scim_hash)

        expect(group.active).to be true
      end
    end

    context "with different resource types" do
      it "handles Departments" do
        group = described_class.upsert_from_scim("Departments", scim_hash)
        expect(group.resource_type).to eq("Departments")
      end

      it "handles Roles" do
        group = described_class.upsert_from_scim("Roles", scim_hash)
        expect(group.resource_type).to eq("Roles")
      end

      it "handles Titles" do
        group = described_class.upsert_from_scim("Titles", scim_hash)
        expect(group.resource_type).to eq("Titles")
      end

      it "handles Territories" do
        group = described_class.upsert_from_scim("Territories", scim_hash)
        expect(group.resource_type).to eq("Territories")
      end

      it "handles Groups" do
        group = described_class.upsert_from_scim("Groups", scim_hash)
        expect(group.resource_type).to eq("Groups")
      end
    end

    context "with invalid SCIM data" do
      it "validates SCIM schema before persisting" do
        invalid_hash = { "id" => "group-123" } # Missing required fields

        expect do
          described_class.upsert_from_scim(resource_type, invalid_hash)
        end.to raise_error(ArgumentError, /schemas attribute is required/)
      end
    end

    context "validation rollback on invalid members" do
      let!(:valid_user) { create_scim_user(scim_id: "valid-user-1") }
      let!(:existing_group) do
        create_scim_group(scim_id: "group-validation", display_name: "Test Group", external_id: "ext-validation")
      end

      it "rolls back scim_data changes when member validation fails" do
        # First attempt: add invalid member
        invalid_member_hash = {
          "id" => existing_group.scim_id,
          "externalId" => existing_group.external_id,
          "displayName" => "Test Group",
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
          "members" => [
            { "value" => "nonexistent-user-1" },
          ],
        }

        expect do
          described_class.upsert_from_scim(resource_type, invalid_member_hash)
        end.to raise_error(ArgumentError, /Cannot add non-existent users/)

        # Verify scim_data was NOT updated with invalid member
        existing_group.reload
        expect(existing_group.scim_data["members"]).to be_nil.or be_empty

        # Second attempt: add different invalid member
        different_invalid_hash = {
          "id" => existing_group.scim_id,
          "externalId" => existing_group.external_id,
          "displayName" => "Test Group",
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
          "members" => [
            { "value" => "nonexistent-user-2" }, # Different invalid user
          ],
        }

        expect do
          described_class.upsert_from_scim(resource_type, different_invalid_hash)
        end.to raise_error(ArgumentError, /Cannot add non-existent users.*nonexistent-user-2/)

        # Verify error references NEW member (not old one from first attempt)
        existing_group.reload
        expect(existing_group.scim_data["members"]).to be_nil.or be_empty
      end

      it "rolls back on partial invalid member list" do
        invalid_mixed_hash = {
          "id" => existing_group.scim_id,
          "externalId" => existing_group.external_id,
          "displayName" => "Test Group",
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
          "members" => [
            { "value" => valid_user.scim_id },       # Valid
            { "value" => "nonexistent-user-3" },     # Invalid
          ],
        }

        expect do
          described_class.upsert_from_scim(resource_type, invalid_mixed_hash)
        end.to raise_error(ArgumentError, /Cannot add non-existent users/)

        # Verify NO members were added (transaction rolled back)
        existing_group.reload
        expect(existing_group.scim_users).to be_empty
        expect(existing_group.scim_data["members"]).to be_nil.or be_empty
      end
    end
  end

  describe ".find_by_scim_id" do
    it "finds group by scim_id" do
      group = create_scim_group(scim_id: "group-456")

      found_group = described_class.find_by_scim_id("group-456")
      expect(found_group).to eq(group)
    end

    it "returns nil when group not found" do
      expect(described_class.find_by_scim_id("nonexistent")).to be_nil
    end
  end

  describe ".exists_by_scim_id?" do
    it "returns true when group exists" do
      create_scim_group(scim_id: "group-789")

      expect(described_class.exists_by_scim_id?("group-789")).to be true
    end

    it "returns false when group does not exist" do
      expect(described_class.exists_by_scim_id?("nonexistent")).to be false
    end
  end

  describe ".destroy_by_scim_id" do
    context "when group exists" do
      let!(:group) { create_scim_group(scim_id: "group-999") }

      it "destroys the group" do
        expect do
          described_class.destroy_by_scim_id("group-999")
        end.to change { described_class.count }.by(-1)
      end

      it "returns the destroyed group" do
        result = described_class.destroy_by_scim_id("group-999")
        expect(result).to be_a(described_class)
        expect(result.scim_id).to eq("group-999")
        expect(result).to be_destroyed
      end
    end

    context "when group does not exist" do
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

  describe "#replace_members" do
    let(:group) { create_scim_group }
    let!(:user1) { create_scim_user(scim_id: "user-1") }
    let!(:user2) { create_scim_user(scim_id: "user-2") }
    let!(:user3) { create_scim_user(scim_id: "user-3") }
    let!(:user4) { create_scim_user(scim_id: "user-4") }

    context "when adding new members" do
      let(:members_array) do
        [
          { "value" => "user-1" },
          { "value" => "user-2" },
        ]
      end

      it "creates memberships for new members" do
        expect do
          group.replace_members(members_array)
        end.to change { group.scim_group_memberships.count }.by(2)

        expect(group.scim_users).to include(user1, user2)
      end
    end

    context "when removing members" do
      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user3, scim_group: group)
      end

      let(:members_array) do
        [{ "value" => "user-1" }] # Only keep user1
      end

      it "removes memberships not in the array" do
        expect do
          group.replace_members(members_array)
        end.to change { group.scim_group_memberships.count }.by(-2)

        group.reload
        expect(group.scim_users).to eq([user1])
        expect(group.scim_users).not_to include(user2, user3)
      end
    end

    context "when members already exist" do
      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
      end

      let(:members_array) do
        [
          { "value" => "user-1" },
          { "value" => "user-2" },
        ]
      end

      it "does not duplicate existing memberships" do
        # Only adds user2
        expect do
          group.replace_members(members_array)
        end.to change { group.scim_group_memberships.count }.by(1)
        expect(group.scim_users).to include(user1, user2)
      end
    end

    context "with empty members array" do
      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)
      end

      it "removes all memberships" do
        expect do
          group.replace_members([])
        end.to change { group.scim_group_memberships.count }.from(2).to(0)
      end

      it "syncs scim_data['members'] to empty array" do
        group.replace_members([])
        group.reload
        expect(group.scim_data["members"]).to eq([])
      end
    end

    context "when scim_data['members'] is out of sync with join table" do
      # Simulates state where join table has members but scim_data["members"] is empty
      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)

        group.scim_data["members"] = []
        group.save!
      end

      it "syncs scim_data['members'] when adding a new member" do
        members_array = [
          { "value" => user1.scim_id },
          { "value" => user2.scim_id },
          { "value" => user3.scim_id },
        ]

        group.replace_members(members_array)
        group.reload

        expect(group.scim_data["members"].size).to eq(3)
        member_values = group.scim_data["members"].map { |m| m["value"] }
        expect(member_values).to contain_exactly(user1.scim_id, user2.scim_id, user3.scim_id)
      end

      it "syncs scim_data['members'] when removing a member" do
        members_array = [{ "value" => user1.scim_id }]

        group.replace_members(members_array)
        group.reload

        expect(group.scim_data["members"].size).to eq(1)
        expect(group.scim_data["members"].first["value"]).to eq(user1.scim_id)
      end

      it "syncs scim_data['members'] when removing all members" do
        group.replace_members([])
        group.reload

        expect(group.scim_data["members"]).to eq([])
      end
    end

    context "complete replacement scenarios" do
      before do
        # Start with user1, user2, user3 in the group
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user3, scim_group: group)
      end

      it "replaces all existing members with entirely new members" do
        # Replace [user1, user2, user3] with [user4]
        members_array = [{ "value" => user4.scim_id }]

        group.replace_members(members_array)
        group.reload

        expect(group.scim_users.count).to eq(1)
        expect(group.scim_users).to eq([user4])
        expect(group.scim_users).not_to include(user1, user2, user3)

        # Verify scim_data synced
        expect(group.scim_data["members"].size).to eq(1)
        expect(group.scim_data["members"].first["value"]).to eq(user4.scim_id)
      end

      it "replaces with partial overlap (keeps some, removes some, adds some)" do
        # Replace [user1, user2, user3] with [user2, user4]
        # Keeps user2, removes user1 and user3, adds user4
        members_array = [
          { "value" => user2.scim_id },
          { "value" => user4.scim_id },
        ]

        group.replace_members(members_array)
        group.reload

        expect(group.scim_users.count).to eq(2)
        expect(group.scim_users).to contain_exactly(user2, user4)
        expect(group.scim_users).not_to include(user1, user3)

        # Verify scim_data synced
        expect(group.scim_data["members"].size).to eq(2)
        member_values = group.scim_data["members"].map { |m| m["value"] }
        expect(member_values).to contain_exactly(user2.scim_id, user4.scim_id)
      end

      it "is idempotent when replacing with same members" do
        # Replace [user1, user2, user3] with [user1, user2, user3]
        members_array = [
          { "value" => user1.scim_id },
          { "value" => user2.scim_id },
          { "value" => user3.scim_id },
        ]

        expect do
          group.replace_members(members_array)
        end.not_to(change { group.scim_group_memberships.count })

        group.reload
        expect(group.scim_users).to contain_exactly(user1, user2, user3)

        # Verify scim_data synced even though no changes to join table
        expect(group.scim_data["members"].size).to eq(3)
        member_values = group.scim_data["members"].map { |m| m["value"] }
        expect(member_values).to contain_exactly(user1.scim_id, user2.scim_id, user3.scim_id)
      end
    end

    context "when member scim_ids do not exist" do
      let(:members_array) do
        [{ "value" => "nonexistent-user" }]
      end

      it "raises error for non-existent users" do
        expect do
          group.replace_members(members_array)
        end.to raise_error(ArgumentError, /Cannot add non-existent users to group: nonexistent-user/)
      end
    end
  end

  describe "#to_domain_attributes" do
    let(:group) { create_scim_group(resource_type: "Departments") }

    it "returns a hash with domain attributes" do
      attributes = group.to_domain_attributes

      expect(attributes).to be_a(Hash)
      expect(attributes).to include(
        :scim_id,
        :external_id,
        :display_name,
        :active,
        :resource_type
      )
    end

    it "includes resource_type" do
      attributes = group.to_domain_attributes

      expect(attributes[:resource_type]).to eq("Departments")
    end
  end

  describe "#to_scim_representation" do
    let(:group) { create_scim_group(resource_type: "Departments") }

    it "returns RFC 7644 compliant SCIM Group resource" do
      scim_repr = group.to_scim_representation

      expect(scim_repr).to be_a(Hash)
      expect(scim_repr["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:Group")
      expect(scim_repr["id"]).to eq(group.scim_id)
    end

    it "includes meta information" do
      scim_repr = group.to_scim_representation

      expect(scim_repr["meta"]).to be_present
      expect(scim_repr["meta"]["resourceType"]).to eq("Departments")
    end

    it "includes core attributes" do
      scim_repr = group.to_scim_representation

      expect(scim_repr).to include("displayName")
    end

    it "includes members array" do
      user1 = create_scim_user(scim_id: "user-1", display_name: "User One")
      user2 = create_scim_user(scim_id: "user-2", display_name: "User Two")
      TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
      TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)

      # Eager-load members to test serialization
      group_with_members = TwoPercent::ScimGroup.includes(:scim_users).find(group.id)
      scim_repr = group_with_members.to_scim_representation

      expect(scim_repr["members"]).to be_an(Array)
      expect(scim_repr["members"].size).to eq(2)
    end
  end

  describe "#scim_attribute" do
    let(:scim_data) do
      {
        "displayName" => "Engineering",
        "meta" => {
          "resourceType" => "Departments",
        },
        "members" => [
          { "value" => "user-1", "display" => "User One" },
        ],
      }
    end
    let(:group) { create_scim_group(scim_data: scim_data) }

    it "returns attribute by dot-notation path" do
      expect(group.scim_attribute("displayName")).to eq("Engineering")
    end

    it "handles nested paths" do
      expect(group.scim_attribute("meta.resourceType")).to eq("Departments")
    end

    it "returns nil for missing paths" do
      expect(group.scim_attribute("nonexistent.path")).to be_nil
    end

    it "handles array paths" do
      expect(group.scim_attribute("members")).to be_an(Array)
    end
  end

  # Test helpers
  def build_scim_group(attributes = {})
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
      active: attributes.fetch(:active, true),
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    described_class.new(full_attributes)
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
      active: attributes.fetch(:active, true),
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimGroup.create!(full_attributes)
  end

  def create_scim_user(attributes = {})
    scim_id = attributes[:scim_id] || "user-#{SecureRandom.hex(4)}"
    external_id = attributes[:external_id] || "ext-#{SecureRandom.hex(4)}"
    display_name = attributes[:display_name] || "Test User"

    default_scim_data = {
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
      "id" => scim_id,
      "externalId" => external_id,
      "userName" => "test.user",
      "displayName" => display_name,
      "emails" => [{ "value" => "test@example.com", "type" => "work", "primary" => true }],
      "active" => true,
    }

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      user_name: "test.user",
      display_name: display_name,
      email: "test@example.com",
      active: true,
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimUser.create!(full_attributes)
  end
end
