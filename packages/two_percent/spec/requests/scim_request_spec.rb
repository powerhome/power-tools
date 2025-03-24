# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scim requests", type: :request do
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
      post "/scim/Users", headers: { "Content-Type" => "application/scim+json" }, params: valid_params

      expect(response).to have_http_status(:ok)
    end

    it "creates a TwoPercent::CreateEvent" do
      expect(TwoPercent::CreateEvent).to receive(:create).with(resource: "Users", params: valid_params)

      post "/scim/Users", params: valid_params
    end
  end
end
