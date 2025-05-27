# frozen_string_literal: true

require "rails_helper"

require_relative "shared/an_authenticated_request"

RSpec.describe "Scim Bulk requests", type: :request do
  let(:headers) { { "Content-Type" => "application/scim+json" } }

  describe "POST /scim/Bulk" do
    it_behaves_like "an authenticated request" do
      subject { post "/scim/Bulk" }
    end

    it "dispatches a bulk operation" do
      operations = [
        Factory.bulk_operation(method: "POST", path: "/Users", data: { "data" => "data" }),
        Factory.bulk_operation(method: "PUT", path: "/Users/123", data: { "data" => "data" }),
      ]
      bulk_request = Factory.bulk_request(operations)
      stub_processor = double("BulkProcessor")

      expect(TwoPercent::BulkProcessor).to(
        receive(:new)
          .with(operations)
          .and_return(stub_processor)
      )
      expect(stub_processor).to receive(:dispatch)

      post "/scim/Bulk", headers: headers, params: bulk_request.to_json
    end
  end
end
