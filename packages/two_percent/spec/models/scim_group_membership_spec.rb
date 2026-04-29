# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScimGroupMembership, type: :model do
  describe "table name" do
    it "uses two_percent_scim_group_memberships table" do
      expect(described_class.table_name).to eq("two_percent_scim_group_memberships")
    end
  end

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

  describe "correlation_id" do
    it "stores correlation_id when provided" do
      user = create_scim_user
      group = create_scim_group
      
      membership = described_class.create!(
        scim_user: user,
        scim_group: group,
        correlation_id: "test-correlation-123"
      )
      
      expect(membership.correlation_id).to eq("test-correlation-123")
    end

    it "allows nil correlation_id" do
      user = create_scim_user
      group = create_scim_group
      
      membership = described_class.create!(
        scim_user: user,
        scim_group: group,
        correlation_id: nil
      )
      
      expect(membership.correlation_id).to be_nil
    end
  end

  describe "database persistence" do
    it "persists to database" do
      user = create_scim_user
      group = create_scim_group
      
      expect {
        described_class.create!(scim_user: user, scim_group: group)
      }.to change { described_class.count }.by(1)
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
      expect {
        user.destroy
      }.to change { described_class.count }.by(-1)
    end

    it "is deleted when group is destroyed" do
      expect {
        group.destroy
      }.to change { described_class.count }.by(-1)
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
    let(:groups) { 3.times.map { create_scim_group } }

    it "can create multiple memberships at once" do
      expect {
        groups.each do |group|
          described_class.create!(scim_user: user, scim_group: group)
        end
      }.to change { described_class.count }.by(3)
    end

    it "can delete multiple memberships at once" do
      groups.each do |group|
        described_class.create!(scim_user: user, scim_group: group)
      end

      expect {
        described_class.where(scim_user: user).destroy_all
      }.to change { described_class.count }.by(-3)
    end
  end

  # Test helpers
  def build_membership(attributes = {})
    default_attributes = {
      scim_user: create_scim_user,
      scim_group: create_scim_group
    }
    described_class.new(default_attributes.merge(attributes))
  end

  def create_scim_user(attributes = {})
    default_attributes = {
      scim_id: "user-#{SecureRandom.hex(4)}",
      external_id: "ext-#{SecureRandom.hex(4)}",
      user_name: "test.user@example.com",
      display_name: "Test User",
      email: "test.user@example.com",
      active: true,
      scim_data: {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => "test",
        "externalId" => "ext-test",
        "userName" => "test.user@example.com",
        "displayName" => "Test User",
        "emails" => [{ "value" => "test.user@example.com", "type" => "work", "primary" => true }],
        "active" => true
      }
    }
    ScimUser.create!(default_attributes.merge(attributes))
  end

  def create_scim_group(attributes = {})
    default_attributes = {
      scim_id: "group-#{SecureRandom.hex(4)}",
      external_id: "ext-#{SecureRandom.hex(4)}",
      display_name: "Test Group",
      resource_type: "Groups",
      active: true,
      scim_data: {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        "id" => "test",
        "displayName" => "Test Group",
        "members" => []
      }
    }
    ScimGroup.create!(default_attributes.merge(attributes))
  end
end
