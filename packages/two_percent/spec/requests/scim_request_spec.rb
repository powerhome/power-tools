# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scim requests", type: :request do
  describe "POST /scim/Users" do
    let(:headers) { { "Content-Type" => "application/scim+json" } }
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
            primary: true,
          },
        ],
      }
    end

    it "accepts the scim+json content type" do
      post "/scim/Users", headers: headers, params: valid_params.to_json

      expect(response).to have_http_status(:ok)
    end
  end
end
