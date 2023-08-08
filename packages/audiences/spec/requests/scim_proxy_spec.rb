# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences/scim", type: :request do
  let(:parsed_body) { JSON.parse(last_response.body) }

  context "GET /audiences/scim" do
    it "proxies the calls to the configured scim service" do
      stub_request(:get, "http://localhost:3002/api/scim/v2/AnythingGoes")
        .with(query: { filter: "name eq John" })
        .to_return(body: '{"anything":"comes"}', status: 201)

      get audience_scim_proxy_path(scim_path: "AnythingGoes", filter: "name eq John")

      expect(parsed_body).to eql("anything" => "comes")
    end

    it "proxies the headers" do
      stub_request(:get, "http://localhost:3002/api/scim/v2/AnythingGoes")
        .with(headers: { "Authorization" => "Bearer 123456789" })
        .to_return(body: '{"anything":"comes"}', status: 201)

      get audience_scim_proxy_path(scim_path: "AnythingGoes")

      expect(parsed_body).to eql("anything" => "comes")
    end
  end
end
