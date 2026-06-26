# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SCIM API", type: :request do
  let(:correlation_id) { "test-correlation-123" }
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json", # Changed from application/scim+json for testing
      "HTTP_X_CORRELATION_ID" => correlation_id,
    }
  end

  # Helper to capture published events
  let(:published_events) { [] }

  before do
    # Stub event creation to capture events instead of actually publishing
    [
      TwoPercent::Domain::Events::UserCreated,
      TwoPercent::Domain::Events::UserUpdated,
      TwoPercent::Domain::Events::UserDeleted,
      TwoPercent::Domain::Events::GroupCreated,
      TwoPercent::Domain::Events::GroupUpdated,
      TwoPercent::Domain::Events::GroupDeleted,
    ].each do |event_class|
      allow(event_class).to receive(:create) do |attributes|
        event = event_class.new(attributes)
        published_events << event
        event
      end
    end
  end

  # ========== POST /scim/Users (Create User) ==========
  describe "POST /scim/Users" do
    let(:scim_user_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        externalId: "ext-user-123",
        userName: "john.doe@example.com",
        name: {
          givenName: "John",
          familyName: "Doe",
        },
        displayName: "John Doe",
        emails: [
          {
            value: "john.doe@example.com",
            type: "work",
            primary: true,
          },
        ],
        active: true,
      }
    end

    context "with valid request" do
      it "returns 201 Created" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        expect(response).to have_http_status(:created)
      end

      it "returns Location header with resource URL" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        expect(response.headers["Location"]).to match(%r{/scim/Users/.+})
      end

      it "returns SCIM User resource in response body" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:User")
        expect(json_response["id"]).to be_present
        expect(json_response["userName"]).to eq("john.doe@example.com")
        expect(json_response["displayName"]).to eq("John Doe")
      end

      it "persists user to database" do
        expect do
          post "/scim/Users", params: scim_user_payload.to_json, headers: headers
        end.to change { TwoPercent::ScimUser.count }.by(1)

        user = TwoPercent::ScimUser.last
        expect(user.user_name).to eq("john.doe@example.com")
        expect(user.display_name).to eq("John Doe")
        expect(user.email).to eq("john.doe@example.com")
        expect(user.active).to be true
      end

      it "stores correlation_id from header" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        user = TwoPercent::ScimUser.last
        expect(user.correlation_id).to eq(correlation_id)
      end

      it "publishes UserCreated domain event" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        expect(published_events.size).to eq(1)
        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::UserCreated)
        expect(event.correlation_id).to eq(correlation_id)
      end

      it "includes domain attributes in event payload" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers

        event = published_events.first
        expect(event.user_attributes).to include(
          :scim_id,
          :external_id,
          :display_name,
          :email,
          :active
        )
        expect(event.user_attributes[:display_name]).to eq("John Doe")
        expect(event.user_attributes[:email]).to eq("john.doe@example.com")
      end
    end

    context "with explicit id in payload" do
      let(:scim_user_with_id) do
        scim_user_payload.merge(id: "explicit-id-from-idp")
      end

      it "uses the provided id instead of generating one" do
        post "/scim/Users", params: scim_user_with_id.to_json, headers: headers

        user = TwoPercent::ScimUser.last
        expect(user.scim_id).to eq("explicit-id-from-idp")
      end

      it "returns the provided id in response" do
        post "/scim/Users", params: scim_user_with_id.to_json, headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq("explicit-id-from-idp")
      end

      it "includes the provided id in Location header" do
        post "/scim/Users", params: scim_user_with_id.to_json, headers: headers

        expect(response.headers["Location"]).to match(%r{/scim/Users/explicit-id-from-idp})
      end
    end

    context "without correlation ID header" do
      let(:headers_without_correlation) do
        { "CONTENT_TYPE" => "application/scim+json" }
      end

      it "generates correlation_id automatically" do
        post "/scim/Users", params: scim_user_payload.to_json, headers: headers_without_correlation

        user = TwoPercent::ScimUser.last
        expect(user.correlation_id).to be_present
        expect(user.correlation_id).to match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
      end
    end

    context "with invalid SCIM data" do
      let(:invalid_payload) do
        { userName: "test" } # Missing required schemas attribute
      end

      it "returns 400 Bad Request" do
        expect do
          post "/scim/Users", params: invalid_payload.to_json, headers: headers
        end.not_to(change { TwoPercent::ScimUser.count })

        expect(response).to have_http_status(:bad_request)
      end

      it "does not publish domain event" do
        expect do
          post "/scim/Users", params: invalid_payload.to_json, headers: headers
        end.not_to(change { published_events.size })
      end
    end

    context "when groups attribute is present in request (intentional RFC deviation for client compatibility)" do
      let!(:test_group) do
        create_scim_group(
          scim_id: "group-999",
          display_name: "Test Group",
          resource_type: "Groups"
        )
      end

      let(:scim_user_with_groups) do
        scim_user_payload.merge(
          groups: [{ value: "group-999", display: "Test Group" }]
        )
      end

      it "syncs group memberships from groups attribute (intentional RFC deviation)" do
        post "/scim/Users", params: scim_user_with_groups.to_json, headers: headers

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        # groups should be populated from the request
        expect(json_response["groups"]).to be_an(Array)
        expect(json_response["groups"].length).to eq(1)
        expect(json_response["groups"].first["value"]).to eq("group-999")
      end

      it "creates group memberships from POST request" do
        post "/scim/Users", params: scim_user_with_groups.to_json, headers: headers

        user = TwoPercent::ScimUser.last
        user.reload
        expect(user.scim_groups.count).to eq(1)
        expect(user.scim_groups.first.scim_id).to eq("group-999")
      end

      it "stores groups in scim_data" do
        post "/scim/Users", params: scim_user_with_groups.to_json, headers: headers

        user = TwoPercent::ScimUser.last
        expect(user.scim_data).to have_key("groups")
        expect(user.scim_data["groups"]).to be_an(Array)
      end
    end
  end

  # Helper method for creating test groups
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
      scim_data: attributes[:scim_data] || default_scim_data,
    }
    TwoPercent::ScimGroup.create!(full_attributes)
  end

  # ========== POST /scim/Groups (Create Group) ==========
  describe "POST /scim/Groups" do
    let(:scim_group_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        externalId: "ext-group-123",
        displayName: "Engineering Team",
        members: [],
      }
    end

    context "with valid request" do
      it "returns 201 Created" do
        post "/scim/Groups", params: scim_group_payload.to_json, headers: headers

        expect(response).to have_http_status(:created)
      end

      it "returns Location header with resource URL" do
        post "/scim/Groups", params: scim_group_payload.to_json, headers: headers

        expect(response.headers["Location"]).to match(%r{/scim/Groups/.+})
      end

      it "persists group to database" do
        expect do
          post "/scim/Groups", params: scim_group_payload.to_json, headers: headers
        end.to change { TwoPercent::ScimGroup.count }.by(1)

        group = TwoPercent::ScimGroup.last
        expect(group.display_name).to eq("Engineering Team")
        expect(group.resource_type).to eq("Groups")
        expect(group.active).to be true
      end

      it "publishes GroupCreated domain event" do
        post "/scim/Groups", params: scim_group_payload.to_json, headers: headers

        expect(published_events.size).to eq(1)
        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::GroupCreated)
        expect(event.resource_type).to eq("Groups")
        expect(event.group_attributes[:display_name]).to eq("Engineering Team")
      end
    end

    context "with explicit id in payload" do
      let(:scim_group_with_id) do
        scim_group_payload.merge(id: "group-from-idp-123")
      end

      it "uses the provided id instead of generating one" do
        post "/scim/Groups", params: scim_group_with_id.to_json, headers: headers

        group = TwoPercent::ScimGroup.last
        expect(group.scim_id).to eq("group-from-idp-123")
      end

      it "returns the provided id in response" do
        post "/scim/Groups", params: scim_group_with_id.to_json, headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq("group-from-idp-123")
      end
    end

    context "with members" do
      let!(:user1) { create_scim_user(scim_id: "user-1", display_name: "User One") }
      let!(:user2) { create_scim_user(scim_id: "user-2", display_name: "User Two") }

      let(:group_with_members) do
        scim_group_payload.merge(
          members: [
            { value: "user-1", display: "User One" },
            { value: "user-2", display: "User Two" },
          ]
        )
      end

      it "creates group memberships" do
        post "/scim/Groups", params: group_with_members.to_json, headers: headers

        group = TwoPercent::ScimGroup.last
        expect(group.scim_users.count).to eq(2)
        expect(group.scim_users).to include(user1, user2)
      end

      it "includes members in SCIM representation" do
        post "/scim/Groups", params: group_with_members.to_json, headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["members"]).to be_an(Array)
        expect(json_response["members"].size).to eq(2)
      end
    end
  end

  # ========== POST /scim/Departments (Create Department) ==========
  describe "POST /scim/Departments" do
    let(:scim_department_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        externalId: "dept-123",
        displayName: "Sales Department",
        members: [],
      }
    end

    it "creates group with resource_type=Departments" do
      post "/scim/Departments", params: scim_department_payload.to_json, headers: headers

      group = TwoPercent::ScimGroup.last
      expect(group.resource_type).to eq("Departments")
      expect(group.display_name).to eq("Sales Department")
    end

    it "publishes GroupCreated event with resource_type=Departments" do
      post "/scim/Departments", params: scim_department_payload.to_json, headers: headers

      event = published_events.first
      expect(event.resource_type).to eq("Departments")
    end
  end

  # ========== PATCH /scim/Users/:id (Update User) ==========
  describe "PATCH /scim/Users/:id" do
    let!(:existing_user) do
      create_scim_user(
        scim_id: "user-456",
        display_name: "Old Name",
        email: "old@example.com"
      )
    end

    let(:patch_operations) do
      {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          {
            op: "replace",
            path: "displayName",
            value: "New Name",
          },
        ],
      }
    end

    context "when user exists" do
      it "returns 200 OK" do
        patch "/scim/Users/user-456", headers: headers, params: patch_operations.to_json

        expect(response).to have_http_status(:ok)
      end

      it "updates user in database" do
        patch "/scim/Users/user-456", headers: headers, params: patch_operations.to_json

        existing_user.reload
        expect(existing_user.display_name).to eq("New Name")
      end

      it "publishes UserUpdated domain event" do
        patch "/scim/Users/user-456", headers: headers, params: patch_operations.to_json

        expect(published_events.size).to eq(1)
        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::UserUpdated)
        expect(event.user_attributes[:display_name]).to eq("New Name")
      end

      it "returns updated SCIM resource" do
        patch "/scim/Users/user-456", headers: headers, params: patch_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["displayName"]).to eq("New Name")
      end
    end

    context "when attempting to modify groups attribute (RFC 7643 read-only)" do
      let!(:test_group) do
        create_scim_group(
          scim_id: "group-999",
          display_name: "Test Group",
          resource_type: "Groups"
        )
      end

      it "rejects PATCH add operation with 400 mutability error" do
        add_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "add",
              path: "groups",
              value: [{ value: "group-999" }],
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: add_operations.to_json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["scimType"]).to eq("mutability")
        expect(json_response["detail"]).to include("read-only")
      end

      it "rejects PATCH remove operation with 400 mutability error" do
        remove_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "remove",
              path: "groups[value eq \"group-999\"]",
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: remove_operations.to_json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["scimType"]).to eq("mutability")
        expect(json_response["detail"]).to include("read-only")
      end

      it "rejects PATCH replace operation with 400 mutability error" do
        replace_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "replace",
              path: "groups",
              value: [{ value: "group-999" }],
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: replace_operations.to_json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["scimType"]).to eq("mutability")
        expect(json_response["detail"]).to include("read-only")
      end

      it "does not publish domain events when groups modification is rejected" do
        add_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "add",
              path: "groups",
              value: [{ value: "group-999" }],
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: add_operations.to_json

        expect(published_events).to be_empty
      end

      it "rejects pathless PATCH replace with groups in value" do
        pathless_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "replace",
              value: {
                active: true,
                groups: [{ value: "group-999" }],
              },
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: pathless_operations.to_json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["scimType"]).to eq("mutability")
        expect(json_response["detail"]).to include("read-only")
      end

      it "rejects pathless PATCH add with groups in value" do
        pathless_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "add",
              value: {
                groups: [{ value: "group-999" }],
              },
            },
          ],
        }

        patch "/scim/Users/user-456", headers: headers, params: pathless_operations.to_json

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["scimType"]).to eq("mutability")
        expect(json_response["detail"]).to include("read-only")
      end
    end

    context "when user does not exist" do
      it "returns 404 Not Found" do
        patch "/scim/Users/nonexistent", headers: headers, params: patch_operations.to_json

        expect(response).to have_http_status(:not_found)
      end

      it "does not publish domain event" do
        patch "/scim/Users/nonexistent", headers: headers, params: patch_operations.to_json

        expect(published_events).to be_empty
      end
    end
  end

  # ========== PATCH /scim/Groups/:id (Update Group Members) ==========
  describe "PATCH /scim/Groups/:id" do
    let!(:existing_group) do
      create_scim_group(
        scim_id: "group-123",
        display_name: "Engineering Team",
        resource_type: "Groups"
      )
    end

    let!(:user1) { create_scim_user(scim_id: "user-1", display_name: "Alice") }
    let!(:user2) { create_scim_user(scim_id: "user-2", display_name: "Bob") }
    let!(:user3) { create_scim_user(scim_id: "user-3", display_name: "Charlie") }

    context "with single add operation" do
      let(:add_member_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "add",
              path: "members",
              value: [
                { value: "user-1", "$ref" => "/Users/user-1", display: "Alice" },
              ],
            },
          ],
        }
      end

      it "returns 200 OK" do
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json

        expect(response).to have_http_status(:ok)
      end

      it "adds member to group" do
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json

        existing_group.reload
        expect(existing_group.scim_users).to include(user1)
        expect(existing_group.scim_users.count).to eq(1)
      end

      it "is idempotent when adding same member twice" do
        # First add
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json
        existing_group.reload
        expect(existing_group.scim_users.count).to eq(1)

        # Second add (idempotent)
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json
        existing_group.reload
        expect(existing_group.scim_users.count).to eq(1)
      end

      it "publishes GroupUpdated event" do
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json

        expect(published_events.size).to eq(1)
        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::GroupUpdated)
        expect(event.group_attributes[:scim_id]).to eq("group-123")
      end

      it "returns updated SCIM representation with members" do
        patch "/scim/Groups/group-123", headers: headers, params: add_member_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["members"].size).to eq(1)
        expect(json_response["members"].first["value"]).to eq("user-1")
      end
    end

    context "adding members to group with existing members (verify append not replace)" do
      let!(:group_with_members) do
        group = create_scim_group(scim_id: "group-789", display_name: "Existing Group")
        group.scim_users = [user1, user2]
        group.save!
        # Update scim_data to reflect current members
        group.scim_data["members"] = [
          { "value" => user1.scim_id, "type" => "User" },
          { "value" => user2.scim_id, "type" => "User" },
        ]
        group.save!
        group
      end

      let(:add_third_member_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "add",
              path: "members",
              value: [{ value: user3.scim_id }],
            },
          ],
        }
      end

      it "appends new member (does not replace existing)" do
        patch "/scim/Groups/group-789", headers: headers, params: add_third_member_operations.to_json

        group_with_members.reload
        expect(group_with_members.scim_users.count).to eq(3)
        expect(group_with_members.scim_users).to contain_exactly(user1, user2, user3)
      end

      it "returns SCIM representation with all members" do
        patch "/scim/Groups/group-789", headers: headers, params: add_third_member_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["members"].size).to eq(3)
        member_ids = json_response["members"].map { |m| m["value"] }
        expect(member_ids).to contain_exactly(user1.scim_id, user2.scim_id, user3.scim_id)
      end
    end

    context "replacing members" do
      let!(:group_with_members) do
        group = create_scim_group(scim_id: "group-replace", display_name: "Replace Group")
        group.scim_users = [user1, user2]
        group.save!
        group.scim_data["members"] = [
          { "value" => user1.scim_id, "type" => "User" },
          { "value" => user2.scim_id, "type" => "User" },
        ]
        group.save!
        group
      end

      let(:replace_members_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "replace",
              path: "members",
              value: [
                { value: user3.scim_id },
                { value: user1.scim_id },
              ],
            },
          ],
        }
      end

      it "replaces all members with new set" do
        patch "/scim/Groups/group-replace", headers: headers, params: replace_members_operations.to_json

        group_with_members.reload
        expect(group_with_members.scim_users.count).to eq(2)
        expect(group_with_members.scim_users).to contain_exactly(user1, user3)
        expect(group_with_members.scim_users).not_to include(user2)
      end

      it "returns SCIM representation with replaced members" do
        patch "/scim/Groups/group-replace", headers: headers, params: replace_members_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["members"].size).to eq(2)
        member_ids = json_response["members"].map { |m| m["value"] }
        expect(member_ids).to contain_exactly(user1.scim_id, user3.scim_id)
      end

      it "can replace with empty array" do
        empty_replace_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "replace", path: "members", value: [] },
          ],
        }

        patch "/scim/Groups/group-replace", headers: headers, params: empty_replace_operations.to_json

        group_with_members.reload
        expect(group_with_members.scim_users).to be_empty
      end
    end

    context "with single remove operation" do
      before do
        # Add members first
        TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: existing_group)
        TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: existing_group)
      end

      let(:remove_member_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "remove",
              path: "members",
            },
          ],
        }
      end

      it "returns 200 OK" do
        patch "/scim/Groups/group-123", headers: headers, params: remove_member_operations.to_json

        expect(response).to have_http_status(:ok)
      end

      it "removes all members from group" do
        patch "/scim/Groups/group-123", headers: headers, params: remove_member_operations.to_json

        existing_group.reload
        expect(existing_group.scim_users).to be_empty
      end

      it "is idempotent when removing from empty group" do
        patch "/scim/Groups/group-123", headers: headers, params: remove_member_operations.to_json
        existing_group.reload
        expect(existing_group.scim_users).to be_empty

        # Second remove (idempotent)
        patch "/scim/Groups/group-123", headers: headers, params: remove_member_operations.to_json
        existing_group.reload
        expect(existing_group.scim_users).to be_empty
      end

      it "returns SCIM representation with empty members array" do
        patch "/scim/Groups/group-123", headers: headers, params: remove_member_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["members"]).to eq([])
      end
    end

    context "removing specific member (with value)" do
      let!(:user3) { create_scim_user(scim_id: "user-3", display_name: "Charlie") }
      let!(:existing_group_with_members) do
        group = create_scim_group(
          scim_id: "group-456",
          display_name: "Test Group"
        )
        group.scim_users = [user1, user2, user3]
        group.save!
        # Update scim_data to reflect current members
        group.scim_data["members"] = [
          { "value" => user1.scim_id, "type" => "User" },
          { "value" => user2.scim_id, "type" => "User" },
          { "value" => user3.scim_id, "type" => "User" },
        ]
        group.save!
        group
      end

      let(:remove_specific_member_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "remove",
              path: "members",
              value: [{ value: user2.scim_id }],
            },
          ],
        }
      end

      it "removes only the specified member (keeps others)" do
        patch "/scim/Groups/group-456", headers: headers, params: remove_specific_member_operations.to_json

        existing_group_with_members.reload
        expect(existing_group_with_members.scim_users.count).to eq(2)
        expect(existing_group_with_members.scim_users).to include(user1, user3)
        expect(existing_group_with_members.scim_users).not_to include(user2)
      end

      it "returns SCIM representation with remaining members" do
        patch "/scim/Groups/group-456", headers: headers, params: remove_specific_member_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["members"].size).to eq(2)
        member_ids = json_response["members"].map { |m| m["value"] }
        expect(member_ids).to contain_exactly(user1.scim_id, user3.scim_id)
      end

      it "is idempotent when removing non-existent member" do
        operations_with_nonexistent = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "remove",
              path: "members",
              value: [{ value: "user-999-nonexistent" }],
            },
          ],
        }

        patch "/scim/Groups/group-456", headers: headers, params: operations_with_nonexistent.to_json

        existing_group_with_members.reload
        expect(existing_group_with_members.scim_users.count).to eq(3)
        expect(existing_group_with_members.scim_users).to contain_exactly(user1, user2, user3)
      end

      it "removes multiple members in one operation" do
        operations_remove_multiple = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "remove",
              path: "members",
              value: [
                { value: user1.scim_id },
                { value: user3.scim_id },
              ],
            },
          ],
        }

        patch "/scim/Groups/group-456", headers: headers, params: operations_remove_multiple.to_json

        existing_group_with_members.reload
        expect(existing_group_with_members.scim_users.count).to eq(1)
        expect(existing_group_with_members.scim_users).to contain_exactly(user2)
      end

      it "returns 200 OK" do
        patch "/scim/Groups/group-456", headers: headers, params: remove_specific_member_operations.to_json

        expect(response).to have_http_status(:ok)
      end
    end

    context "with multiple operations in one request" do
      context "multiple add operations" do
        let(:multi_add_operations) do
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
            Operations: [
              {
                op: "add",
                path: "members",
                value: [{ value: "user-1" }],
              },
              {
                op: "add",
                path: "members",
                value: [{ value: "user-2" }],
              },
            ],
          }
        end

        it "applies both add operations" do
          patch "/scim/Groups/group-123", headers: headers, params: multi_add_operations.to_json

          existing_group.reload
          expect(existing_group.scim_users).to include(user1, user2)
          expect(existing_group.scim_users.count).to eq(2)
        end
      end

      context "add then remove operations" do
        let(:add_then_remove_operations) do
          {
            schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
            Operations: [
              {
                op: "add",
                path: "members",
                value: [
                  { value: "user-1" },
                  { value: "user-2" },
                  { value: "user-3" },
                ],
              },
              {
                op: "remove",
                path: "members",
              },
            ],
          }
        end

        it "applies operations sequentially (final state: empty)" do
          patch "/scim/Groups/group-123", headers: headers, params: add_then_remove_operations.to_json

          existing_group.reload
          expect(existing_group.scim_users).to be_empty
        end
      end
    end

    context "with mixed operations (members + displayName)" do
      let(:mixed_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            {
              op: "replace",
              path: "displayName",
              value: "Updated Team Name",
            },
            {
              op: "add",
              path: "members",
              value: [
                { value: "user-1" },
                { value: "user-2" },
              ],
            },
          ],
        }
      end

      it "applies all operations correctly" do
        patch "/scim/Groups/group-123", headers: headers, params: mixed_operations.to_json

        existing_group.reload
        expect(existing_group.display_name).to eq("Updated Team Name")
        expect(existing_group.scim_users).to include(user1, user2)
        expect(existing_group.scim_users.count).to eq(2)
      end

      it "returns updated SCIM representation with all changes" do
        patch "/scim/Groups/group-123", headers: headers, params: mixed_operations.to_json

        json_response = JSON.parse(response.body)
        expect(json_response["displayName"]).to eq("Updated Team Name")
        expect(json_response["members"].size).to eq(2)
      end
    end

    context "when group does not exist" do
      let(:add_operations) do
        {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "add", path: "members", value: [{ value: "user-1" }] },
          ],
        }
      end

      it "returns 404 Not Found" do
        patch "/scim/Groups/nonexistent", headers: headers, params: add_operations.to_json

        expect(response).to have_http_status(:not_found)
      end

      it "does not publish domain event" do
        patch "/scim/Groups/nonexistent", headers: headers, params: add_operations.to_json

        expect(published_events).to be_empty
      end
    end

    context "when scim_data is out of sync with join table" do
      # Simulates scenario where scim_data["members"] is empty/stale but join table has members
      # This can happen due to direct database manipulation, bugs, or inconsistent state
      let!(:user3) { create_scim_user(scim_id: "user-3", display_name: "Charlie") }
      let!(:user4) { create_scim_user(scim_id: "user-4", display_name: "Diana") }
      let!(:group_with_stale_scim_data) do
        group = create_scim_group(
          scim_id: "group-stale-data",
          display_name: "Group With Stale Data"
        )
        # Set up join table with existing members
        group.scim_users = [user1, user2, user3]
        group.save!

        # Simulate stale scim_data (empty despite join table having members)
        group.scim_data["members"] = []
        group.save!
        group
      end

      it "PATCH add preserves existing members when scim_data is stale" do
        add_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "add", path: "members", value: [{ value: user4.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-stale-data", headers: headers, params: add_operations.to_json

        group_with_stale_scim_data.reload
        # Expected: Preserves existing members [user1, user2, user3] and adds user4
        expect(group_with_stale_scim_data.scim_users.count).to eq(4)
        expect(group_with_stale_scim_data.scim_users).to contain_exactly(user1, user2, user3, user4)
      end

      it "PATCH remove works correctly when scim_data is stale" do
        remove_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "remove", path: "members", value: [{ value: user2.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-stale-data", headers: headers, params: remove_operations.to_json

        group_with_stale_scim_data.reload
        # Expected: Removes user2, keeps others
        expect(group_with_stale_scim_data.scim_users.count).to eq(2)
        expect(group_with_stale_scim_data.scim_users).to contain_exactly(user1, user3)
      end

      it "PATCH replace works correctly when scim_data is stale" do
        replace_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "replace", path: "members", value: [{ value: user3.scim_id }, { value: user4.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-stale-data", headers: headers, params: replace_operations.to_json

        group_with_stale_scim_data.reload
        # Expected: Replaces all with new set [user3, user4]
        expect(group_with_stale_scim_data.scim_users.count).to eq(2)
        expect(group_with_stale_scim_data.scim_users).to contain_exactly(user3, user4)
      end

      it "syncs join table after operations" do
        add_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "add", path: "members", value: [{ value: user4.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-stale-data", headers: headers, params: add_operations.to_json

        group_with_stale_scim_data.reload
        # Verify join table has all members
        expect(group_with_stale_scim_data.scim_users.count).to eq(4)
        member_scim_ids = group_with_stale_scim_data.scim_users.pluck(:scim_id)
        expect(member_scim_ids).to contain_exactly(user1.scim_id, user2.scim_id, user3.scim_id, user4.scim_id)
      end
    end

    context "when scim_data['members'] has never been set" do
      let!(:group_without_scim_members) do
        group = create_scim_group(scim_id: "group-no-members")
        # scim_data["members"] is nil/absent (never set)
        group.scim_users = [user1, user2]
        group.save!
        group
      end

      it "PATCH add works when scim_data['members'] is nil" do
        add_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "add", path: "members", value: [{ value: user3.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-no-members", headers: headers, params: add_operations.to_json

        expect(response).to have_http_status(:ok)
        group_without_scim_members.reload
        expect(group_without_scim_members.scim_users.count).to eq(3)
        expect(group_without_scim_members.scim_users).to include(user1, user2, user3)
      end

      it "PATCH remove works when scim_data['members'] is nil" do
        remove_operations = {
          schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
          Operations: [
            { op: "remove", path: "members", value: [{ value: user2.scim_id }] },
          ],
        }

        patch "/scim/Groups/group-no-members", headers: headers, params: remove_operations.to_json

        expect(response).to have_http_status(:ok)
        group_without_scim_members.reload
        expect(group_without_scim_members.scim_users.count).to eq(1)
        expect(group_without_scim_members.scim_users).to contain_exactly(user1)
      end
    end
  end

  # ========== PUT /scim/Users/:id (Replace User) ==========
  describe "PUT /scim/Users/:id" do
    let(:full_user_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        externalId: "ext-replaced",
        userName: "replaced@example.com",
        name: {
          givenName: "Replaced",
          familyName: "User",
        },
        displayName: "Replaced User",
        emails: [
          {
            value: "replaced@example.com",
            type: "work",
            primary: true,
          },
        ],
        active: true,
      }
    end

    context "when user does not exist (create)" do
      it "returns 201 Created" do
        put "/scim/Users/new-user-789", headers: headers, params: full_user_payload.to_json

        expect(response).to have_http_status(:created)
      end

      it "returns Location header" do
        put "/scim/Users/new-user-789", headers: headers, params: full_user_payload.to_json

        expect(response.headers["Location"]).to match(%r{/scim/Users/new-user-789})
      end

      it "creates user in database" do
        expect do
          put "/scim/Users/new-user-789", headers: headers, params: full_user_payload.to_json
        end.to change { TwoPercent::ScimUser.count }.by(1)

        user = TwoPercent::ScimUser.find_by(scim_id: "new-user-789")
        expect(user.display_name).to eq("Replaced User")
      end

      it "publishes UserCreated event" do
        put "/scim/Users/new-user-789", headers: headers, params: full_user_payload.to_json

        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::UserCreated)
      end
    end

    context "when user already exists (replace)" do
      let!(:existing_user) do
        create_scim_user(
          scim_id: "existing-999",
          display_name: "Old User",
          email: "old@example.com"
        )
      end

      it "returns 200 OK" do
        put "/scim/Users/existing-999", headers: headers, params: full_user_payload.to_json

        expect(response).to have_http_status(:ok)
      end

      it "does not return Location header" do
        put "/scim/Users/existing-999", headers: headers, params: full_user_payload.to_json

        expect(response.headers["Location"]).to be_nil
      end

      it "replaces user data" do
        put "/scim/Users/existing-999", headers: headers, params: full_user_payload.to_json

        existing_user.reload
        expect(existing_user.display_name).to eq("Replaced User")
        expect(existing_user.email).to eq("replaced@example.com")
      end

      it "publishes UserUpdated event" do
        put "/scim/Users/existing-999", headers: headers, params: full_user_payload.to_json

        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::UserUpdated)
      end
    end

    context "when groups attribute is present in request (intentional RFC deviation for client compatibility)" do
      let!(:existing_user) do
        create_scim_user(scim_id: "user-with-group-attempt", display_name: "Test User")
      end

      let!(:test_group) do
        create_scim_group(
          scim_id: "group-888",
          display_name: "Attempted Group",
          resource_type: "Groups"
        )
      end

      let(:user_payload_with_groups) do
        full_user_payload.merge(
          id: "user-with-group-attempt",
          groups: [{ value: "group-888", display: "Attempted Group" }]
        )
      end

      it "syncs group memberships from groups attribute (intentional RFC deviation)" do
        put "/scim/Users/user-with-group-attempt", headers: headers, params: user_payload_with_groups.to_json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        # groups should be populated from the request
        expect(json_response["groups"]).to be_an(Array)
        expect(json_response["groups"].length).to eq(1)
        expect(json_response["groups"].first["value"]).to eq("group-888")
      end

      it "creates group memberships from PUT request" do
        put "/scim/Users/user-with-group-attempt", headers: headers, params: user_payload_with_groups.to_json

        existing_user.reload
        expect(existing_user.scim_groups.count).to eq(1)
        expect(existing_user.scim_groups.first.scim_id).to eq("group-888")
      end

      it "stores groups in scim_data" do
        put "/scim/Users/user-with-group-attempt", headers: headers, params: user_payload_with_groups.to_json

        existing_user.reload
        expect(existing_user.scim_data).to have_key("groups")
        expect(existing_user.scim_data["groups"]).to be_an(Array)
      end
    end
  end

  # ========== DELETE /scim/Users/:id (Delete User) ==========
  describe "DELETE /scim/Users/:id" do
    let!(:user_to_delete) do
      create_scim_user(scim_id: "delete-me-123")
    end

    context "when user exists" do
      it "returns 204 No Content" do
        delete "/scim/Users/delete-me-123", headers: headers

        expect(response).to have_http_status(:no_content)
      end

      it "returns empty response body" do
        delete "/scim/Users/delete-me-123", headers: headers

        expect(response.body).to be_empty
      end

      it "deletes user from database" do
        expect do
          delete "/scim/Users/delete-me-123", headers: headers
        end.to change { TwoPercent::ScimUser.count }.by(-1)

        expect(TwoPercent::ScimUser.exists_by_scim_id?("delete-me-123")).to be false
      end

      it "publishes UserDeleted domain event" do
        delete "/scim/Users/delete-me-123", headers: headers

        expect(published_events.size).to eq(1)
        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::UserDeleted)
        expect(event.user_id).to eq("delete-me-123")
      end

      it "includes correlation_id in event" do
        delete "/scim/Users/delete-me-123", headers: headers

        event = published_events.first
        expect(event.correlation_id).to eq(correlation_id)
      end
    end

    context "when user does not exist" do
      it "returns 404 Not Found" do
        delete "/scim/Users/nonexistent", headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "does not publish domain event" do
        delete "/scim/Users/nonexistent", headers: headers

        expect(published_events).to be_empty
      end
    end

    context "with group memberships" do
      let!(:group) { create_scim_group }

      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user_to_delete, scim_group: group)
      end

      it "cascades delete to memberships" do
        expect do
          delete "/scim/Users/delete-me-123", headers: headers
        end.to change { TwoPercent::ScimGroupMembership.count }.by(-1)
      end
    end
  end

  # ========== DELETE /scim/Groups/:id (Delete Group) ==========
  describe "DELETE /scim/Groups/:id" do
    let!(:group_to_delete) do
      create_scim_group(scim_id: "group-delete-456", resource_type: "Departments")
    end

    context "when group exists" do
      it "returns 204 No Content" do
        delete "/scim/Departments/group-delete-456", headers: headers

        expect(response).to have_http_status(:no_content)
      end

      it "deletes group from database" do
        expect do
          delete "/scim/Departments/group-delete-456", headers: headers
        end.to change { TwoPercent::ScimGroup.count }.by(-1)
      end

      it "publishes GroupDeleted domain event" do
        delete "/scim/Departments/group-delete-456", headers: headers

        event = published_events.first
        expect(event).to be_a(TwoPercent::Domain::Events::GroupDeleted)
        expect(event.group_id).to eq("group-delete-456")
        expect(event.resource_type).to eq("Departments")
      end
    end

    context "with members" do
      let!(:user) { create_scim_user }

      before do
        TwoPercent::ScimGroupMembership.create!(scim_user: user, scim_group: group_to_delete)
      end

      it "cascades delete to memberships" do
        expect do
          delete "/scim/Departments/group-delete-456", headers: headers
        end.to change { TwoPercent::ScimGroupMembership.count }.by(-1)
      end

      it "does not delete users" do
        expect do
          delete "/scim/Departments/group-delete-456", headers: headers
        end.not_to(change { TwoPercent::ScimUser.count })
      end
    end
  end

  # ========== Content-Type Handling ==========
  describe "Content-Type handling" do
    let(:scim_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:User"],
        externalId: "test",
        userName: "test@example.com",
        displayName: "Test",
        emails: [{ value: "test@example.com", type: "work", primary: true }],
      }
    end

    it "accepts application/scim+json" do
      post "/scim/Users",
           params: scim_payload.to_json,
           headers: { "CONTENT_TYPE" => "application/scim+json" }

      expect(response).to have_http_status(:created)
    end

    it "accepts application/json" do
      post "/scim/Users",
           params: scim_payload.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:created)
    end
  end

  # ========== Resource Type Validation ==========
  describe "Resource type validation" do
    let(:valid_payload) do
      {
        schemas: ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        externalId: "test",
        displayName: "Test Group",
      }
    end

    it "supports Groups resource type" do
      post "/scim/Groups", params: valid_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
    end

    it "supports Departments resource type" do
      post "/scim/Departments", params: valid_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      expect(TwoPercent::ScimGroup.last.resource_type).to eq("Departments")
    end

    it "supports Territories resource type" do
      post "/scim/Territories", params: valid_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      expect(TwoPercent::ScimGroup.last.resource_type).to eq("Territories")
    end

    it "supports Roles resource type" do
      post "/scim/Roles", params: valid_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      expect(TwoPercent::ScimGroup.last.resource_type).to eq("Roles")
    end

    it "supports Titles resource type" do
      post "/scim/Titles", params: valid_payload.to_json, headers: headers
      expect(response).to have_http_status(:created)
      expect(TwoPercent::ScimGroup.last.resource_type).to eq("Titles")
    end

    context "with unknown resource type" do
      it "returns 400 Bad Request with error message" do
        post "/scim/UnknownType", params: valid_payload.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
        expect(json["detail"]).to eq("Unknown resource type: UnknownType")
      end
    end

    context "with custom group_resource_types configuration" do
      before do
        @original_config = TwoPercent.config.group_resource_types
        TwoPercent.config.group_resource_types = %w[Groups Teams]
      end

      after do
        TwoPercent.config.group_resource_types = @original_config
      end

      it "accepts configured resource types" do
        post "/scim/Teams", params: valid_payload.to_json, headers: headers
        expect(response).to have_http_status(:created)
        expect(TwoPercent::ScimGroup.last.resource_type).to eq("Teams")
      end

      it "rejects non-configured resource types" do
        post "/scim/Departments", params: valid_payload.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)

        json = JSON.parse(response.body)
        expect(json["detail"]).to eq("Unknown resource type: Departments")
      end
    end
  end

  # ========== GET /scim/Users/:id (Retrieve Single User) ==========
  describe "GET /scim/Users/:id" do
    let!(:existing_user) do
      create_scim_user(
        scim_id: "get-user-123",
        display_name: "John Doe",
        email: "john@example.com"
      )
    end

    context "when user exists" do
      it "returns 200 OK" do
        get "/scim/Users/get-user-123", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns SCIM User resource with correct schemas" do
        get "/scim/Users/get-user-123", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:User")
      end

      it "returns user with id and meta" do
        get "/scim/Users/get-user-123", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq("get-user-123")
        expect(json_response["displayName"]).to eq("John Doe")
        expect(json_response["meta"]).to be_present
        expect(json_response["meta"]["resourceType"]).to eq("User")
      end

      it "includes created and lastModified timestamps in meta" do
        get "/scim/Users/get-user-123", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["meta"]["created"]).to be_present
        expect(json_response["meta"]["lastModified"]).to be_present
      end

      it "does not publish domain events (read-only)" do
        get "/scim/Users/get-user-123", headers: headers

        expect(published_events).to be_empty
      end
    end

    context "when user does not exist" do
      it "returns 404 Not Found" do
        get "/scim/Users/nonexistent-user", headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "returns RFC 7644 error response" do
        get "/scim/Users/nonexistent-user", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
        expect(json_response["scimType"]).to eq("noTarget")
      end
    end
  end

  # ========== GET /scim/Groups/:id (Retrieve Single Group) ==========
  describe "GET /scim/Groups/:id" do
    let!(:user1) { create_scim_user(scim_id: "member-1", display_name: "Alice") }
    let!(:user2) { create_scim_user(scim_id: "member-2", display_name: "Bob") }
    let!(:existing_group) do
      group = create_scim_group(
        scim_id: "get-group-456",
        display_name: "Engineering Team",
        resource_type: "Groups"
      )
      TwoPercent::ScimGroupMembership.create!(scim_user: user1, scim_group: group)
      TwoPercent::ScimGroupMembership.create!(scim_user: user2, scim_group: group)
      group
    end

    context "when group exists" do
      it "returns 200 OK" do
        get "/scim/Groups/get-group-456", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns SCIM Group resource with correct schemas" do
        get "/scim/Groups/get-group-456", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:Group")
      end

      it "returns group with members" do
        get "/scim/Groups/get-group-456", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq("get-group-456")
        expect(json_response["displayName"]).to eq("Engineering Team")
        expect(json_response["members"]).to be_an(Array)
        expect(json_response["members"].size).to eq(2)
      end

      it "includes meta with resourceType" do
        get "/scim/Groups/get-group-456", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["meta"]["resourceType"]).to eq("Groups")
      end
    end

    context "when group does not exist" do
      it "returns 404 Not Found" do
        get "/scim/Groups/nonexistent-group", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # ========== GET /scim/Departments/:id (Retrieve Single Department) ==========
  describe "GET /scim/Departments/:id" do
    let!(:department) do
      create_scim_group(
        scim_id: "dept-789",
        display_name: "Sales Department",
        resource_type: "Departments"
      )
    end

    it "returns department with correct resource_type in meta" do
      get "/scim/Departments/dept-789", headers: headers

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["meta"]["resourceType"]).to eq("Departments")
    end
  end

  # ========== GET /scim/Users (List Users with RFC 7644 ListResponse) ==========
  describe "GET /scim/Users" do
    let!(:user1) { create_scim_user(scim_id: "list-user-1", display_name: "Alice Anderson") }
    let!(:user2) { create_scim_user(scim_id: "list-user-2", display_name: "Bob Brown") }
    let!(:user3) { create_scim_user(scim_id: "list-user-3", display_name: "Charlie Chen") }

    context "without query parameters" do
      it "returns 200 OK" do
        get "/scim/Users", headers: headers

        expect(response).to have_http_status(:ok)
      end

      it "returns RFC 7644 ListResponse format" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:ListResponse")
        expect(json_response).to have_key("totalResults")
        expect(json_response).to have_key("startIndex")
        expect(json_response).to have_key("itemsPerPage")
        expect(json_response).to have_key("Resources")
      end

      it "returns all users in Resources array" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(3)
        expect(json_response["Resources"]).to be_an(Array)
        expect(json_response["Resources"].size).to eq(3)
      end

      it "returns users with full SCIM representation" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        first_user = json_response["Resources"].first
        expect(first_user["schemas"]).to include("urn:ietf:params:scim:schemas:core:2.0:User")
        expect(first_user["id"]).to be_present
        expect(first_user["displayName"]).to be_present
        expect(first_user["meta"]).to be_present
      end

      it "defaults startIndex to 1" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["startIndex"]).to eq(1)
      end

      it "does not publish domain events (read-only)" do
        get "/scim/Users", headers: headers

        expect(published_events).to be_empty
      end
    end

    context "with pagination parameters" do
      it "respects count parameter" do
        get "/scim/Users?count=2", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(3)
        expect(json_response["itemsPerPage"]).to eq(2)
        expect(json_response["Resources"].size).to eq(2)
      end

      it "respects startIndex parameter (1-based)" do
        get "/scim/Users?startIndex=2&count=2", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["startIndex"]).to eq(2)
        expect(json_response["Resources"].size).to eq(2)
        # Should skip first user
        expect(json_response["Resources"].map { |u| u["id"] }).not_to include("list-user-1")
      end

      it "handles startIndex beyond results" do
        get "/scim/Users?startIndex=100", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(3)
        expect(json_response["Resources"]).to eq([])
        expect(json_response["itemsPerPage"]).to eq(0)
      end

      it "enforces maximum count limit" do
        get "/scim/Users?count=10000", headers: headers

        json_response = JSON.parse(response.body)
        # Should cap at maximum (1000)
        expect(json_response["itemsPerPage"]).to be <= 1000
      end
    end

    context "with query filter parameter" do
      it "filters by display_name substring match" do
        get "/scim/Users?query=Alice", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(1)
        expect(json_response["Resources"].first["displayName"]).to eq("Alice Anderson")
      end

      it "is case-insensitive" do
        get "/scim/Users?query=alice", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(1)
      end

      it "returns empty array when no matches" do
        get "/scim/Users?query=Nonexistent", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(0)
        expect(json_response["Resources"]).to eq([])
      end

      it "combines query with pagination" do
        get "/scim/Users?query=n&count=1", headers: headers

        json_response = JSON.parse(response.body)
        # Should match "Anderson", "Brown", "Chen" (3 total)
        expect(json_response["totalResults"]).to eq(3)
        expect(json_response["itemsPerPage"]).to eq(1)
        expect(json_response["Resources"].size).to eq(1)
      end

      it "escapes LIKE wildcards in query parameter" do
        # Verify wildcards are treated as literals, not pattern operators
        get "/scim/Users?query=#{CGI.escape('_')}", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(0) # No matches (not single-char wildcard)
      end
    end

    context "with empty results" do
      before do
        TwoPercent::ScimUser.delete_all
      end

      it "returns empty Resources array" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["totalResults"]).to eq(0)
        expect(json_response["Resources"]).to eq([])
        expect(json_response["itemsPerPage"]).to eq(0)
      end

      it "maintains RFC 7644 format" do
        get "/scim/Users", headers: headers

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      end
    end
  end

  # ========== GET /scim/Groups (List Groups with RFC 7644 ListResponse) ==========
  describe "GET /scim/Groups" do
    let!(:group1) { create_scim_group(scim_id: "list-group-1", display_name: "Engineering", resource_type: "Groups") }
    let!(:group2) { create_scim_group(scim_id: "list-group-2", display_name: "Marketing", resource_type: "Groups") }

    it "returns RFC 7644 ListResponse format" do
      get "/scim/Groups", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:ListResponse")
      expect(json_response["totalResults"]).to eq(2)
      expect(json_response["Resources"]).to be_an(Array)
    end

    it "filters by query parameter" do
      get "/scim/Groups?query=Engineer", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response["totalResults"]).to eq(1)
      expect(json_response["Resources"].first["displayName"]).to eq("Engineering")
    end
  end

  # ========== GET /scim/Departments (List Departments) ==========
  describe "GET /scim/Departments" do
    let!(:dept1) { create_scim_group(scim_id: "dept-1", display_name: "Sales", resource_type: "Departments") }
    let!(:dept2) { create_scim_group(scim_id: "dept-2", display_name: "Support", resource_type: "Departments") }
    let!(:group) { create_scim_group(scim_id: "other-1", display_name: "Other Group", resource_type: "Groups") }

    it "returns only Departments resource_type" do
      get "/scim/Departments", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response["totalResults"]).to eq(2)
      json_response["Resources"].each do |resource|
        expect(resource["meta"]["resourceType"]).to eq("Departments")
      end
    end

    it "does not include other resource types" do
      get "/scim/Departments", headers: headers

      json_response = JSON.parse(response.body)
      resource_ids = json_response["Resources"].map { |r| r["id"] }
      expect(resource_ids).not_to include("other-1")
    end
  end

  # ========== GET /scim/Territories (List Territories) ==========
  describe "GET /scim/Territories" do
    let!(:territory) { create_scim_group(scim_id: "terr-1", display_name: "Northeast", resource_type: "Territories") }

    it "returns only Territories resource_type" do
      get "/scim/Territories", headers: headers

      json_response = JSON.parse(response.body)
      expect(json_response["totalResults"]).to eq(1)
      expect(json_response["Resources"].first["meta"]["resourceType"]).to eq("Territories")
    end
  end

  # ========== GET with Invalid Resource Types (Validation) ==========
  describe "GET with invalid resource type" do
    context "GET /scim/:resource_type/:id (show)" do
      it "returns 400 Bad Request for unknown resource type" do
        get "/scim/InvalidType/some-id", headers: headers

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
        expect(json_response["detail"]).to eq("Unknown resource type: InvalidType")
      end
    end

    context "GET /scim/:resource_type (index)" do
      it "returns 400 Bad Request for unknown resource type" do
        get "/scim/InvalidType", headers: headers

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
        expect(json_response["detail"]).to eq("Unknown resource type: InvalidType")
      end
    end
  end

  # Test helpers
  def create_scim_user(attributes = {})
    scim_id = attributes[:scim_id] || "user-#{SecureRandom.hex(4)}"
    external_id = attributes[:external_id] || "ext-#{SecureRandom.hex(4)}"
    display_name = attributes[:display_name] || "Test User"

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      user_name: "test.user@example.com",
      display_name: display_name,
      email: "test.user@example.com",
      active: true,
      scim_data: {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => scim_id,
        "externalId" => external_id,
        "userName" => "test.user@example.com",
        "displayName" => display_name,
        "emails" => [{ "value" => "test.user@example.com", "type" => "work", "primary" => true }],
        "active" => true,
      },
    }
    TwoPercent::ScimUser.create!(full_attributes)
  end

  def create_scim_group(attributes = {})
    scim_id = attributes[:scim_id] || "group-#{SecureRandom.hex(4)}"
    external_id = attributes[:external_id] || "ext-#{SecureRandom.hex(4)}"
    display_name = attributes[:display_name] || "Test Group"
    resource_type = attributes[:resource_type] || "Groups"

    full_attributes = {
      scim_id: scim_id,
      external_id: external_id,
      display_name: display_name,
      resource_type: resource_type,
      active: true,
      scim_data: {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        "id" => scim_id,
        "externalId" => external_id,
        "displayName" => display_name,
      },
    }
    TwoPercent::ScimGroup.create!(full_attributes)
  end
end
