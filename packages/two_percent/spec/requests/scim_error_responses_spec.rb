# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SCIM Error Responses (RFC 7644 Section 3.12)", type: :request do
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_CORRELATION_ID" => "test-correlation-123"
    }
  end

  describe "404 Not Found errors" do
    it "includes scimType: noTarget" do
      delete "/scim/Users/nonexistent-user-id", headers: headers

      expect(response).to have_http_status(:not_found)
      
      json_response = JSON.parse(response.body)
      expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
      expect(json_response["status"]).to eq("404")
      expect(json_response["scimType"]).to eq("noTarget")
      expect(json_response["detail"]).to be_present
    end
  end

  describe "400 Bad Request errors" do
    it "includes scimType: invalidSyntax for malformed PATCH" do
      # First create a user to PATCH
      TwoPercent::ScimUser.create!(
        scim_id: "user-123",
        external_id: "ext-123",
        user_name: "test@example.com",
        scim_data: {
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
          "id" => "user-123",
          "externalId" => "ext-123",
          "userName" => "test@example.com"
        }
      )

      # Send malformed PATCH (missing Operations array)
      patch "/scim/Users/user-123", headers: headers, params: { invalid: "data" }.to_json

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
      expect(json_response["status"]).to eq("400")
      expect(json_response["scimType"]).to eq("invalidSyntax")
      expect(json_response["detail"]).to be_present
    end

    it "includes scimType: invalidValue for missing schemas" do
      post "/scim/Users", headers: headers, params: { userName: "test" }.to_json

      expect(response).to have_http_status(:bad_request)
      
      json_response = JSON.parse(response.body)
      expect(json_response["schemas"]).to include("urn:ietf:params:scim:api:messages:2.0:Error")
      expect(json_response["status"]).to eq("400")
      expect(json_response["scimType"]).to eq("invalidValue")
      expect(json_response["detail"]).to match(/schemas/i)
    end
  end

  describe "RFC 7644 compliance" do
    it "error response structure matches RFC specification" do
      delete "/scim/Groups/nonexistent", headers: headers

      json_response = JSON.parse(response.body)
      
      # RFC 7644 Section 3.12 requires these fields
      expect(json_response).to have_key("schemas")
      expect(json_response).to have_key("status")
      expect(json_response).to have_key("detail")
      
      # scimType is optional but should be present for 404
      expect(json_response).to have_key("scimType")
      
      # Verify structure
      expect(json_response["schemas"]).to be_an(Array)
      expect(json_response["status"]).to be_a(String)
      expect(json_response["detail"]).to be_a(String)
      expect(json_response["scimType"]).to be_a(String)
    end
  end
end
