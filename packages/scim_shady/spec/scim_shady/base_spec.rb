# frozen_string_literal: true

RSpec.describe ScimShady::Base do
  describe "attribute assignment" do
    let(:object) { User.new({"displayName" => "John Doe"}) }

    it "allows initializing with the schema attributes" do
      expect(object.displayName).to eql "John Doe"
    end
  end
end
