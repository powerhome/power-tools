# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::Subject do
  subject { Consent::Subject.new(ExampleModel, "Subject") }
  let(:view) { Consent::View.new(:view, "View") }
  let(:action) { Consent::Action.new(subject, :action, "Action") }
  before do
    Consent.default_views[:view] = view
    subject.actions << action
  end

  describe "#key" do
    it "is a lazily loaded reference to the actual subject" do
      expect(subject.key).to be ExampleModel
    end

    it "is the model even when defined as a string" do
      another_subect = Consent::Subject.new("ExampleModel", "Subject")

      expect(another_subect.key).to be ExampleModel
    end

    it "is the symbol even when defined as a symbol" do
      another_subect = Consent::Subject.new(:my_subject, "Subject")

      expect(another_subect.key).to be :my_subject
    end
  end

  describe "#views" do
    it "starts as the default_views" do
      expect(subject.views[:view]).to be view
    end
  end

  describe "#to_permission_payload" do
    it "returns the correct hash" do
      expect(subject.to_permission_payload).to eq({
                                                    subject: ExampleModel,
                                                    label: "Subject",
                                                    actions: [action.to_permission_payload],
                                                    views: [view.to_permission_payload],
                                                  })
    end
  end
end
