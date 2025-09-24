# frozen_string_literal: true

require "rails_helper"

require_relative "shared/an_authenticated_request"

RSpec.describe "Scim Resource requests", type: :request do
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

    before do
      allow(TwoPercent::CreateEvent).to receive(:create)
    end

    it_behaves_like "an authenticated request" do
      subject { post "/scim/Users" }
    end

    it "accepts the scim+json content type" do
      post "/scim/Users", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::CreateEvent" do
      post "/scim/Users", headers: headers, params: valid_params.to_json

      expect(TwoPercent::CreateEvent).to have_received(:create) do |resource:, params:|
        expect(resource).to eql "Users"
        expect(params).to match valid_params
        expect(params).to be_a HashWithIndifferentAccess
      end
    end
  end

  describe "PATCH /scim/Users/:id" do
    let(:valid_params) do
      {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        id: "123",
        Operations: [
          {
            op: "replace",
            path: "active",
            value: "true",
          },
        ],
      }
    end

    before do
      allow(TwoPercent::UpdateEvent).to receive(:create)
    end

    it_behaves_like "an authenticated request" do
      subject { patch "/scim/Users/123" }
    end

    it "accepts the scim+json content type" do
      patch "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::UpdateEvent" do
      patch "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(TwoPercent::UpdateEvent).to have_received(:create) do |resource:, id:, params:|
        expect(resource).to eql "Users"
        expect(id).to eql "123"
        expect(params).to match valid_params
        expect(params).to be_a HashWithIndifferentAccess
      end
    end
  end

  describe "PUT /scim/Users/:id" do
    let(:valid_params) do
      {
        id: "123",
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

    before do
      allow(TwoPercent::ReplaceEvent).to receive(:create)
    end

    it_behaves_like "an authenticated request" do
      subject { put "/scim/Users/123" }
    end

    it "accepts the scim+json content type" do
      put "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::ReplaceEvent" do
      put "/scim/Users/123", headers: headers, params: valid_params.to_json

      expect(TwoPercent::ReplaceEvent).to have_received(:create) do |resource:, id:, params:|
        expect(resource).to eql "Users"
        expect(id).to eql "123"
        expect(params).to match valid_params
        expect(params).to be_a HashWithIndifferentAccess
      end
    end
  end

  describe "DELETE /scim/Users/:id" do
    before do
      allow(TwoPercent::DeleteEvent).to receive(:create)
    end

    it_behaves_like "an authenticated request" do
      subject { delete "/scim/Users/123" }
    end

    it "accepts the scim+json content type" do
      delete "/scim/Users/123", headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::ReplaceEvent" do
      delete "/scim/Users/123", headers: headers

      expect(TwoPercent::DeleteEvent).to have_received(:create).with(resource: "Users", id: "123")
    end
  end
end
