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
  end

  # Test helpers
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
        "externalId" => "ext-#{SecureRandom.hex(4)}",
        "userName" => "test.user@example.com",
        "displayName" => "Test User",
        "emails" => [{ "value" => "test.user@example.com", "type" => "work", "primary" => true }],
        "active" => true,
      },
    }
    TwoPercent::ScimUser.create!(default_attributes.merge(attributes))
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
        "members" => [],
      },
    }
    TwoPercent::ScimGroup.create!(default_attributes.merge(attributes))
  end
end
