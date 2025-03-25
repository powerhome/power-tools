# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scim requests", type: :request do
  let(:headers) { { "Content-Type" => "application/scim+json" } }
  describe "POST /scim/Users" do
    let(:valid_params) do
      {
        userName: "test_user",
        name: {
          givenName: "Test",
          familyName: "User",
        },
        emails: [
          {
            value: "test_user@example.com",
            primary: "true",
          },
        ],
      }
    end

    it "accepts the scim+json content type" do
      post "/scim/Users", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::CreateEvent" do
      expect(TwoPercent::CreateEvent).to receive(:create).with(resource: "Users", params: valid_params)

      post "/scim/Users", headers: headers, params: valid_params.to_json
    end
  end

  describe "PATCH /scim/Users/:id" do
    let(:valid_params) do
      {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          {
            op: "replace",
            path: "active",
            value: "true",
          },
        ],
      }
    end

    it "accepts the scim+json content type" do
      patch "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::UpdateEvent" do
      expect(TwoPercent::UpdateEvent).to receive(:create).with(resource: "Users", id: "123", params: valid_params)

      patch "/scim/Users/123", headers: headers, params: valid_params.to_json
    end
  end

  describe "PUT /scim/Users/:id" do
    let(:valid_params) do
      {
        userName: "test_user",
        name: {
          givenName: "Test",
          familyName: "User",
        },
        emails: [
          {
            value: "test_user@example.com",
            primary: "true",
          },
        ],
      }
    end

    it "accepts the scim+json content type" do
      put "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::ReplaceEvent" do
      expect(TwoPercent::ReplaceEvent).to receive(:create).with(resource: "Users", id: "123", params: valid_params)

      put "/scim/Users/123", headers: headers, params: valid_params.to_json
    end
  end

  describe "PATCH /scim/Users/:id" do
    let(:valid_params) do
      {
        userName: "test_user",
        name: {
          givenName: "Test",
          familyName: "User",
        },
        emails: [
          {
            value: "test_user@example.com",
            primary: "true",
          },
        ],
      }
    end

    it "accepts the scim+json content type" do
      patch "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::ReplaceEvent" do
      expect(TwoPercent::UpdateEvent).to receive(:create).with(resource: "Users", id: "123", params: valid_params)

      patch "/scim/Users/123", headers: headers, params: valid_params.to_json
    end
  end

  describe "DELETE /scim/Users/:id" do
    it "accepts the scim+json content type" do
      delete "/scim/Users/123", headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::ReplaceEvent" do
      expect(TwoPercent::DeleteEvent).to receive(:create).with(resource: "Users", id: "123")

      delete "/scim/Users/123", headers: headers
    end
  end
end
