# frozen_string_literal: true

RSpec.describe Audiences do
  describe ".sign" do
    it "creates a signed token to a given context" do
      cricket_club = ExampleOwner.create(name: "Cricket Club")

      token = Audiences.sign(cricket_club)
      context = Audiences.load(token)

      expect(context.owner).to eql cricket_club
    end
  end
end
