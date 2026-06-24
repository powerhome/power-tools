# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::ScimGroupMembership, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:scim_user) }
    it { is_expected.to belong_to(:scim_group) }
  end

  describe "validations" do
    subject(:membership) { build_membership }

    it "validates presence of scim_user" do
      membership.scim_user = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:scim_user]).to be_present
    end

    it "validates presence of scim_group" do
      membership.scim_group = nil
      expect(membership).not_to be_valid
      expect(membership.errors[:scim_group]).to be_present
    end

    context "uniqueness validation" do
      let!(:user) { create_scim_user }
      let!(:group) { create_scim_group }
      let!(:existing_membership) do
        described_class.create!(scim_user: user, scim_group: group)
      end

      it "prevents duplicate memberships for the same user and group" do
        duplicate = described_class.new(scim_user: user, scim_group: group)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:scim_user_id]).to be_present
      end

      it "allows the same user in different groups" do
        other_group = create_scim_group
        membership = described_class.new(scim_user: user, scim_group: other_group)

        expect(membership).to be_valid
      end

      it "allows different users in the same group" do
        other_user = create_scim_user
        membership = described_class.new(scim_user: other_user, scim_group: group)

        expect(membership).to be_valid
      end
    end
  end

  describe "database persistence" do
    it "persists to database" do
      user = create_scim_user
      group = create_scim_group

      expect do
        described_class.create!(scim_user: user, scim_group: group)
      end.to change { described_class.count }.by(1)
    end

    it "can be retrieved from database" do
      user = create_scim_user
      group = create_scim_group
      membership = described_class.create!(scim_user: user, scim_group: group)

      retrieved = described_class.find(membership.id)
      expect(retrieved.scim_user).to eq(user)
      expect(retrieved.scim_group).to eq(group)
    end
  end

  describe "cascade delete behavior" do
    let(:user) { create_scim_user }
    let(:group) { create_scim_group }
    let!(:membership) { described_class.create!(scim_user: user, scim_group: group) }

    it "is deleted when user is destroyed" do
      expect do
        user.destroy
      end.to change { described_class.count }.by(-1)
    end

    it "is deleted when group is destroyed" do
      expect do
        group.destroy
      end.to change { described_class.count }.by(-1)
    end
  end

  describe "querying memberships" do
    let!(:user1) { create_scim_user(scim_id: "user-1") }
    let!(:user2) { create_scim_user(scim_id: "user-2") }
    let!(:group1) { create_scim_group(scim_id: "group-1") }
    let!(:group2) { create_scim_group(scim_id: "group-2") }

    before do
      described_class.create!(scim_user: user1, scim_group: group1)
      described_class.create!(scim_user: user1, scim_group: group2)
      described_class.create!(scim_user: user2, scim_group: group1)
    end

    it "finds all memberships for a user" do
      memberships = described_class.where(scim_user: user1)
      expect(memberships.count).to eq(2)
    end

    it "finds all memberships for a group" do
      memberships = described_class.where(scim_group: group1)
      expect(memberships.count).to eq(2)
    end

    it "finds specific user-group membership" do
      membership = described_class.find_by(scim_user: user1, scim_group: group1)
      expect(membership).to be_present
    end
  end

  describe "bulk operations" do
    let(:user) { create_scim_user }
    let(:groups) { Array.new(3) { create_scim_group } }

    it "can create multiple memberships at once" do
      expect do
        groups.each do |group|
          described_class.create!(scim_user: user, scim_group: group)
        end
      end.to change { described_class.count }.by(3)
    end

    it "can delete multiple memberships at once" do
      groups.each do |group|
        described_class.create!(scim_user: user, scim_group: group)
      end

      expect do
        described_class.where(scim_user: user).destroy_all
      end.to change { described_class.count }.by(-3)
    end
  end

  # Test helpers
  def build_membership(attributes = {})
    default_attributes = {
      scim_user: create_scim_user,
      scim_group: create_scim_group,
    }
    described_class.new(default_attributes.merge(attributes))
  end

  def create_scim_user(attributes = {})
    scim_id = attributes[:scim_id] || "user-#{SecureRandom.hex(4)}"
    external_id = attributes[:external_id] || "ext-#{SecureRandom.hex(4)}"
    display_name = attributes[:display_name] || "Test User"

    default_scim_data = {
      "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
      "id" => scim_id,
      "externalId" => external_id,
      "userName" => "test.user@example.com",
      "displayName" => display_name,
      "emails" => [{ "value" => "test.user@example.com", "type" => "work", "primary" => true }],
      "active" => true,
    }

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      user_name: "test.user@example.com",
      display_name: display_name,
      email: "test.user@example.com",
      active: true,
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimUser.create!(full_attributes)
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
    }

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      display_name: display_name,
      resource_type: resource_type,
      active: true,
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimGroup.create!(full_attributes)
  end
end
