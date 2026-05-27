# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::Action do
  let(:view1) { Consent::View.new(:view1, "View 1") }
  let(:subject) { Consent::Subject.new(:subject, "Subject") }
  let(:options) { { views: [:view1] } }
  let(:action) { Consent::Action.new(subject, :key, "Label", options) }
  before do
    Consent.default_views[:view1] = view1
  end

  it "has a key" do
    expect(action.key).to eql :key
  end

  it "has a label" do
    expect(action.label).to eql "Label"
  end

  describe "#to_permission_payload" do
    it "returns the correct hash" do
      expect(action.to_permission_payload).to eq({
                                                    action: :key,
                                                    label: "Label",
                                                    views: action.views.values.map(&:to_permission_payload),
                                                    default_view: nil,
                                                  })
    end
  end
end
