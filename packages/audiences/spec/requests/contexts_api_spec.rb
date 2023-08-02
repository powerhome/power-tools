# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/audiences", type: :request do
  let(:parsed_body) { JSON.parse(last_response.body) }

  context "GET /audiences/:context_key" do    
    let(:example_owner) { ExampleOwner.create(name: "Example Owner") }
    let(:context_key) { Audiences.sign(example_owner).to_s }

    it "responds with the audience context json" do
      get audiences.context_path(context_key), format: :json

      expect(parsed_body).to match({ "key" => anything, "match_all" => false })
    end

    it "responds with a valid context context_key" do
      get audiences.context_path(context_key), format: :json
      audience = Audiences.load(parsed_body["key"])

      expect(audience.owner).to eql example_owner
    end
  end
end
