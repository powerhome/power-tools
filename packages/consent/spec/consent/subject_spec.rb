# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::Subject do
  subject { Consent::Subject.new(:subject, "Subject") }
  let(:view) { Consent::View.new(:view, "View") }
  let(:action) { Consent::Action.new(subject, :action, "Action") }
  before do
    Consent.default_views[:view] = view
    subject.actions << action
  end

  describe "#views" do
    it "starts as the default_views" do
      expect(subject.views[:view]).to be view
    end
  end

  describe "#to_permission_payload" do
    it "returns the correct hash" do
      expect(subject.to_permission_payload).to eq({
                                                    subject: :subject,
                                                    label: "Subject",
                                                    actions: [action.to_permission_payload],
                                                    views: [view.to_permission_payload],
                                                  })
    end
  end
end
