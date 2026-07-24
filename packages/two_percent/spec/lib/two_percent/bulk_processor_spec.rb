# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::BulkProcessor do
  describe "#dispatch" do
    let(:correlation_id) { "test-correlation-#{SecureRandom.hex(4)}" }

    before do
      # Clear any existing test data
      TwoPercent::ScimUser.destroy_all
      TwoPercent::ScimGroup.destroy_all
    end

    describe "POST operations" do
      it "creates a User from bulk operation" do
        operations = [
          {
            method: "POST",
            path: "/Users",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "bulk-ext-#{SecureRandom.hex(4)}",
              "userName" => "bulk.user@example.com",
              "displayName" => "Bulk User",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserCreated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user = TwoPercent::ScimUser.find_by(user_name: "bulk.user@example.com")
        expect(user).to be_present
        expect(user.display_name).to eq("Bulk User")
        expect(user.correlation_id).to eq(correlation_id)

        expect(TwoPercent::Domain::Events::UserCreated).to have_received(:create).with(
          hash_including(
            user_attributes: hash_including(scim_id: user.scim_id),
            correlation_id: correlation_id
          )
        )
      end

      it "creates a Group from bulk operation" do
        operations = [
          {
            method: "POST",
            path: "/Groups",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
              "externalId" => "bulk-group-#{SecureRandom.hex(4)}",
              "displayName" => "Bulk Group",
              "members" => [],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupCreated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        group = TwoPercent::ScimGroup.find_by(display_name: "Bulk Group")
        expect(group).to be_present
        expect(group.resource_type).to eq("Groups")
        expect(group.correlation_id).to eq(correlation_id)

        expect(TwoPercent::Domain::Events::GroupCreated).to have_received(:create).with(
          hash_including(
            group_attributes: hash_including(scim_id: group.scim_id),
            resource_type: "Groups",
            correlation_id: correlation_id
          )
        )
      end

      it "creates a Department from bulk operation" do
        operations = [
          {
            method: "POST",
            path: "/Departments",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
              "externalId" => "bulk-dept-#{SecureRandom.hex(4)}",
              "displayName" => "Engineering Department",
              "members" => [],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupCreated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        dept = TwoPercent::ScimGroup.find_by(display_name: "Engineering Department", resource_type: "Departments")
        expect(dept).to be_present
        expect(dept.resource_type).to eq("Departments")
      end
    end

    describe "PUT operations" do
      it "updates existing User via bulk operation" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "bulk-ext-#{SecureRandom.hex(4)}",
                                                       "userName" => "existing.user@example.com",
                                                       "displayName" => "Original Name",
                                                       "active" => true,
                                                     })

        operations = [
          {
            method: "PUT",
            path: "/Users/#{user.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => user.external_id,
              "userName" => "existing.user@example.com",
              "displayName" => "Updated Name via Bulk",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user.reload
        expect(user.display_name).to eq("Updated Name via Bulk")
        expect(user.correlation_id).to eq(correlation_id)

        expect(TwoPercent::Domain::Events::UserUpdated).to have_received(:create).with(
          hash_including(
            user_attributes: hash_including(scim_id: user.scim_id),
            correlation_id: correlation_id
          )
        )
      end

      it "creates new User if not exists (upsert behavior)" do
        non_existent_id = "bulk-new-#{SecureRandom.uuid}"

        operations = [
          {
            method: "PUT",
            path: "/Users/#{non_existent_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "bulk-ext-new",
              "userName" => "new.user@example.com",
              "displayName" => "New User via PUT",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user = TwoPercent::ScimUser.find_by(scim_id: non_existent_id)
        expect(user).to be_present
        expect(user.display_name).to eq("New User via PUT")
      end
    end

    describe "PATCH operations" do
      it "patches existing User via bulk operation using RFC 7644 PatchOp format" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "bulk-patch-#{SecureRandom.hex(4)}",
                                                       "userName" => "patch.user@example.com",
                                                       "displayName" => "Original Patch Name",
                                                       "active" => true,
                                                     })

        operations = [
          {
            method: "PATCH",
            path: "/Users/#{user.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
              "Operations" => [
                {
                  "op" => "replace",
                  "path" => "displayName",
                  "value" => "Patched Name via Bulk",
                },
              ],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user.reload
        expect(user.display_name).to eq("Patched Name via Bulk")
        expect(user.user_name).to eq("patch.user@example.com") # Other fields preserved
      end

      it "patches Group members via bulk operation using RFC 7644 PatchOp format" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "member-#{SecureRandom.hex(4)}",
                                                       "userName" => "member.user@example.com",
                                                       "displayName" => "Member User",
                                                       "active" => true,
                                                     })

        group = TwoPercent::ScimGroup.upsert_from_scim("Groups", {
                                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
                                                         "externalId" => "bulk-group-#{SecureRandom.hex(4)}",
                                                         "displayName" => "Test Group",
                                                         "members" => [],
                                                       })

        operations = [
          {
            method: "PATCH",
            path: "/Groups/#{group.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
              "Operations" => [
                {
                  "op" => "add",
                  "path" => "members",
                  "value" => [{ "value" => user.scim_id }],
                },
              ],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        group.reload
        expect(group.scim_users.pluck(:scim_id)).to include(user.scim_id)
        expect(group.display_name).to eq("Test Group") # Other fields preserved
      end

      it "removes specific member from Group via bulk operation" do
        user1 = TwoPercent::ScimUser.upsert_from_scim({
                                                        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                        "externalId" => "member1-#{SecureRandom.hex(4)}",
                                                        "userName" => "user1@example.com",
                                                        "displayName" => "User One",
                                                        "active" => true,
                                                      })

        user2 = TwoPercent::ScimUser.upsert_from_scim({
                                                        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                        "externalId" => "member2-#{SecureRandom.hex(4)}",
                                                        "userName" => "user2@example.com",
                                                        "displayName" => "User Two",
                                                        "active" => true,
                                                      })

        group = TwoPercent::ScimGroup.upsert_from_scim("Groups", {
                                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
                                                         "externalId" => "bulk-remove-#{SecureRandom.hex(4)}",
                                                         "displayName" => "Test Group",
                                                         "members" => [
                                                           { "value" => user1.scim_id },
                                                           { "value" => user2.scim_id },
                                                         ],
                                                       })

        operations = [
          {
            method: "PATCH",
            path: "/Groups/#{group.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
              "Operations" => [
                {
                  "op" => "remove",
                  "path" => "members",
                  "value" => [{ "value" => user2.scim_id }],
                },
              ],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        group.reload
        expect(group.scim_users.count).to eq(1)
        expect(group.scim_users.pluck(:scim_id)).to contain_exactly(user1.scim_id)
      end

      it "removes all members from Group via bulk operation" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "member-#{SecureRandom.hex(4)}",
                                                       "userName" => "user@example.com",
                                                       "displayName" => "User",
                                                       "active" => true,
                                                     })

        group = TwoPercent::ScimGroup.upsert_from_scim("Groups", {
                                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
                                                         "externalId" => "bulk-remove-all-#{SecureRandom.hex(4)}",
                                                         "displayName" => "Test Group",
                                                         "members" => [{ "value" => user.scim_id }],
                                                       })

        operations = [
          {
            method: "PATCH",
            path: "/Groups/#{group.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
              "Operations" => [
                { "op" => "remove", "path" => "members" },
              ],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        group.reload
        expect(group.scim_users).to be_empty
      end
    end

    describe "DELETE operations" do
      it "deletes User via bulk operation" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "bulk-delete-#{SecureRandom.hex(4)}",
                                                       "userName" => "delete.user@example.com",
                                                       "displayName" => "To Be Deleted",
                                                       "active" => true,
                                                     })

        user_id = user.scim_id

        operations = [
          {
            method: "DELETE",
            path: "/Users/#{user_id}",
            data: {},
          },
        ]

        allow(TwoPercent::Domain::Events::UserDeleted).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        expect(TwoPercent::ScimUser.exists_by_scim_id?(user_id)).to be false

        expect(TwoPercent::Domain::Events::UserDeleted).to have_received(:create).with(
          hash_including(
            user_id: user_id,
            correlation_id: correlation_id
          )
        )
      end

      it "deletes Group and cascades to memberships" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "member-#{SecureRandom.hex(4)}",
                                                       "userName" => "member@example.com",
                                                       "displayName" => "Member User",
                                                       "active" => true,
                                                     })

        group = TwoPercent::ScimGroup.upsert_from_scim("Groups", {
                                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
                                                         "externalId" => "bulk-delete-group-#{SecureRandom.hex(4)}",
                                                         "displayName" => "To Be Deleted Group",
                                                         "members" => [{ "value" => user.scim_id,
                                                                         "display" => user.display_name }],
                                                       })

        group_id = group.scim_id
        expect(group.scim_group_memberships.count).to eq(1)

        operations = [
          {
            method: "DELETE",
            path: "/Groups/#{group_id}",
            data: {},
          },
        ]

        allow(TwoPercent::Domain::Events::GroupDeleted).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        expect(TwoPercent::ScimGroup.exists_by_scim_id?(group_id)).to be false
        expect(TwoPercent::ScimGroupMembership.where(scim_group_id: group.id).count).to eq(0) # Cascaded

        expect(TwoPercent::Domain::Events::GroupDeleted).to have_received(:create).with(
          hash_including(
            group_id: group_id,
            resource_type: "Groups",
            correlation_id: correlation_id
          )
        )
      end
    end

    describe "multiple operations in sequence" do
      it "processes multiple operations in order" do
        operations = [
          {
            method: "POST",
            path: "/Users",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "multi-1",
              "userName" => "user1@example.com",
              "displayName" => "User 1",
              "active" => true,
            },
          },
          {
            method: "POST",
            path: "/Users",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "multi-2",
              "userName" => "user2@example.com",
              "displayName" => "User 2",
              "active" => true,
            },
          },
          {
            method: "POST",
            path: "/Groups",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
              "externalId" => "multi-group",
              "displayName" => "Multi Group",
              "members" => [],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserCreated).to receive(:create)
        allow(TwoPercent::Domain::Events::GroupCreated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        expect(TwoPercent::ScimUser.where(user_name: ["user1@example.com", "user2@example.com"]).count).to eq(2)
        expect(TwoPercent::ScimGroup.where(display_name: "Multi Group").count).to eq(1)

        expect(TwoPercent::Domain::Events::UserCreated).to have_received(:create).twice
        expect(TwoPercent::Domain::Events::GroupCreated).to have_received(:create).once
      end

      it "creates then updates the same resource" do
        new_user_id = "bulk-seq-#{SecureRandom.uuid}"

        operations = [
          {
            method: "POST",
            path: "/Users",
            data: {
              "id" => new_user_id,
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "seq-user",
              "userName" => "seq@example.com",
              "displayName" => "Sequential User",
              "active" => true,
            },
          },
          {
            method: "PUT",
            path: "/Users/#{new_user_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "seq-user",
              "userName" => "seq@example.com",
              "displayName" => "Updated Sequential User",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserCreated).to receive(:create)
        allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user = TwoPercent::ScimUser.find_by(scim_id: new_user_id)
        expect(user.display_name).to eq("Updated Sequential User")
      end
    end

    describe "transaction rollback on error" do
      it "rolls back operation if event publishing fails" do
        allow(TwoPercent::Domain::Events::UserCreated).to receive(:create).and_raise(StandardError, "Event system down")

        operations = [
          {
            method: "POST",
            path: "/Users",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "rollback-test",
              "userName" => "rollback@example.com",
              "displayName" => "Rollback Test",
              "active" => true,
            },
          },
        ]

        processor = described_class.new(operations, correlation_id: correlation_id)

        expect do
          processor.dispatch
        end.to raise_error(StandardError, "Event system down")

        # Verify rollback - user should not exist
        expect(TwoPercent::ScimUser.find_by(user_name: "rollback@example.com")).to be_nil
      end
    end

    describe "unknown HTTP method" do
      it "raises error for unsupported method" do
        operations = [
          {
            method: "OPTIONS",
            path: "/Users",
            data: {},
          },
        ]

        processor = described_class.new(operations, correlation_id: correlation_id)

        expect do
          processor.dispatch
        end.to raise_error(ArgumentError, "Unknown HTTP method: OPTIONS")
      end
    end

    describe "path parsing" do
      it "parses resource type from path" do
        operations = [
          {
            method: "POST",
            path: "/Territories",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
              "externalId" => "north-region",
              "displayName" => "North Region",
              "members" => [],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupCreated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        territory = TwoPercent::ScimGroup.find_by(display_name: "North Region", resource_type: "Territories")
        expect(territory).to be_present
      end

      it "parses resource ID from path for updates" do
        user = TwoPercent::ScimUser.upsert_from_scim({
                                                       "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                       "externalId" => "path-parse-#{SecureRandom.hex(4)}",
                                                       "userName" => "pathparse@example.com",
                                                       "displayName" => "Path Parse",
                                                       "active" => true,
                                                     })

        operations = [
          {
            method: "PUT",
            path: "/Users/#{user.scim_id}",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => user.external_id,
              "userName" => "pathparse@example.com",
              "displayName" => "Path Parsed Successfully",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

        processor = described_class.new(operations, correlation_id: correlation_id)
        processor.dispatch

        user.reload
        expect(user.display_name).to eq("Path Parsed Successfully")
      end
    end

    describe "correlation ID propagation" do
      it "passes correlation ID to repository methods" do
        operations = [
          {
            method: "POST",
            path: "/Users",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
              "externalId" => "corr-#{SecureRandom.hex(4)}",
              "userName" => "correlation@example.com",
              "displayName" => "Correlation Test",
              "active" => true,
            },
          },
        ]

        allow(TwoPercent::Domain::Events::UserCreated).to receive(:create)

        custom_correlation = "custom-correlation-id"
        processor = described_class.new(operations, correlation_id: custom_correlation)
        processor.dispatch

        user = TwoPercent::ScimUser.find_by(user_name: "correlation@example.com")
        expect(user.correlation_id).to eq(custom_correlation)
      end

      it "passes correlation ID to domain events" do
        operations = [
          {
            method: "POST",
            path: "/Groups",
            data: {
              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
              "externalId" => "event-corr-group",
              "displayName" => "Event Correlation Group",
              "members" => [],
            },
          },
        ]

        allow(TwoPercent::Domain::Events::GroupCreated).to receive(:create)

        custom_correlation = "event-correlation-id"
        processor = described_class.new(operations, correlation_id: custom_correlation)
        processor.dispatch

        expect(TwoPercent::Domain::Events::GroupCreated).to have_received(:create).with(
          hash_including(correlation_id: custom_correlation)
        )
      end
    end

    describe "User.groups syncing (intentional RFC deviation for client compatibility)" do
      let!(:test_group) do
        TwoPercent::ScimGroup.upsert_from_scim("Groups", {
                                                 "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
                                                 "externalId" => "test-group-#{SecureRandom.hex(4)}",
                                                 "displayName" => "Test Group",
                                                 "members" => [],
                                               })
      end

      let!(:existing_user) do
        TwoPercent::ScimUser.upsert_from_scim({
                                                "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                "externalId" => "user-bulk-#{SecureRandom.hex(4)}",
                                                "userName" => "bulk.readonly@example.com",
                                                "displayName" => "Bulk Readonly User",
                                                "active" => true,
                                              })
      end

      context "POST operations" do
        it "syncs groups attribute from bulk POST (intentional RFC deviation)" do
          operations = [
            {
              method: "POST",
              path: "/Users",
              data: {
                "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                "externalId" => "post-sync-#{SecureRandom.hex(4)}",
                "userName" => "post.sync@example.com",
                "displayName" => "Post Sync Groups",
                "active" => true,
                "groups" => [{ "value" => test_group.scim_id, "display" => test_group.display_name }],
              },
            },
          ]

          allow(TwoPercent::Domain::Events::UserCreated).to receive(:create)

          processor = described_class.new(operations, correlation_id: correlation_id)
          processor.dispatch

          user = TwoPercent::ScimUser.find_by(user_name: "post.sync@example.com")
          expect(user).to be_present

          # Groups should be set from POST
          user.reload
          expect(user.scim_groups.count).to eq(1)
          expect(user.scim_groups.first.scim_id).to eq(test_group.scim_id)

          # Groups should NOT be stored in scim_data (single source of truth: join table)
          expect(user.scim_data).not_to have_key("groups")
        end
      end

      context "PUT operations" do
        it "syncs groups attribute from bulk PUT (intentional RFC deviation)" do
          operations = [
            {
              method: "PUT",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                "externalId" => "put-sync-#{SecureRandom.hex(4)}",
                "userName" => "put.sync@example.com",
                "displayName" => "Put Sync Groups",
                "active" => true,
                "groups" => [{ "value" => test_group.scim_id, "display" => test_group.display_name }],
              },
            },
          ]

          allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

          processor = described_class.new(operations, correlation_id: correlation_id)
          processor.dispatch

          existing_user.reload
          expect(existing_user.display_name).to eq("Put Sync Groups")

          # Groups should be set from PUT
          expect(existing_user.scim_groups.count).to eq(1)
          expect(existing_user.scim_groups.first.scim_id).to eq(test_group.scim_id)

          # Groups should NOT be stored in scim_data (single source of truth: join table)
          expect(existing_user.scim_data).not_to have_key("groups")
        end
      end

      context "PATCH operations" do
        it "raises ReadOnlyAttributeError when attempting to add groups per RFC 7643 Section 4.1.2" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "add",
                    "path" => "groups",
                    "value" => [{ "value" => test_group.scim_id }],
                  },
                ],
              },
            },
          ]

          processor = described_class.new(operations, correlation_id: correlation_id)

          expect do
            processor.dispatch
          end.to raise_error(TwoPercent::ReadOnlyAttributeError, /Attribute 'groups' is read-only/)
        end

        it "raises ReadOnlyAttributeError when attempting to remove groups" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "remove",
                    "path" => "groups[value eq \"#{test_group.scim_id}\"]",
                  },
                ],
              },
            },
          ]

          processor = described_class.new(operations, correlation_id: correlation_id)

          expect do
            processor.dispatch
          end.to raise_error(TwoPercent::ReadOnlyAttributeError, /Attribute 'groups' is read-only/)
        end

        it "raises ReadOnlyAttributeError when attempting to replace groups" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "replace",
                    "path" => "groups",
                    "value" => [{ "value" => test_group.scim_id }],
                  },
                ],
              },
            },
          ]

          processor = described_class.new(operations, correlation_id: correlation_id)

          expect do
            processor.dispatch
          end.to raise_error(TwoPercent::ReadOnlyAttributeError, /Attribute 'groups' is read-only/)
        end

        it "allows other PATCH operations on Users to proceed normally" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "replace",
                    "path" => "displayName",
                    "value" => "Patched Display Name",
                  },
                ],
              },
            },
          ]

          allow(TwoPercent::Domain::Events::UserUpdated).to receive(:create)

          processor = described_class.new(operations, correlation_id: correlation_id)
          processor.dispatch

          existing_user.reload
          expect(existing_user.display_name).to eq("Patched Display Name")
        end

        it "raises ReadOnlyAttributeError for pathless PATCH replace with groups in value" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "replace",
                    "value" => {
                      "active" => true,
                      "groups" => [{ "value" => test_group.scim_id }],
                    },
                  },
                ],
              },
            },
          ]

          processor = described_class.new(operations, correlation_id: correlation_id)

          expect do
            processor.dispatch
          end.to raise_error(TwoPercent::ReadOnlyAttributeError, /Attribute 'groups' is read-only/)
        end

        it "raises ReadOnlyAttributeError for pathless PATCH add with groups in value" do
          operations = [
            {
              method: "PATCH",
              path: "/Users/#{existing_user.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "add",
                    "value" => {
                      "groups" => [{ "value" => test_group.scim_id }],
                    },
                  },
                ],
              },
            },
          ]

          processor = described_class.new(operations, correlation_id: correlation_id)

          expect do
            processor.dispatch
          end.to raise_error(TwoPercent::ReadOnlyAttributeError, /Attribute 'groups' is read-only/)
        end
      end

      context "Group operations (control test)" do
        it "allows PATCH operations on Group.members as expected" do
          user = TwoPercent::ScimUser.upsert_from_scim({
                                                         "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                         "externalId" => "member-bulk-#{SecureRandom.hex(4)}",
                                                         "userName" => "member.bulk@example.com",
                                                         "displayName" => "Member Bulk",
                                                         "active" => true,
                                                       })

          operations = [
            {
              method: "PATCH",
              path: "/Groups/#{test_group.scim_id}",
              data: {
                "schemas" => ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
                "Operations" => [
                  {
                    "op" => "add",
                    "path" => "members",
                    "value" => [{ "value" => user.scim_id }],
                  },
                ],
              },
            },
          ]

          allow(TwoPercent::Domain::Events::GroupUpdated).to receive(:create)

          processor = described_class.new(operations, correlation_id: correlation_id)
          processor.dispatch

          test_group.reload
          expect(test_group.scim_users.pluck(:scim_id)).to include(user.scim_id)
        end
      end
    end
  end
end
