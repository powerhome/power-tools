# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::View do
  let(:obj) { double(id: "1235") }

  describe "#conditions" do
    it "is the callable with the given args" do
      view = Consent::View.new(nil, nil, nil, lambda(&:id))

      expect(view.conditions(obj)).to eql "1235"
    end
  end

  describe "#to_h" do
    it "returns the correct hash" do
      view = Consent::View.new(:view, "View")
      expect(view.to_h).to eq({
                                view: :view,
                                label: "View",
                              })
    end
  end
end
