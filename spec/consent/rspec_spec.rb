# frozen_string_literal: true

require 'spec_helper'
require 'consent/rspec'

RSpec.describe Consent::Rspec do
  include Consent::Rspec

  describe "consent_action" do
    it "validates if a given subject has the given action" do
      expect(SomeModel).to consent_action(:destroy)
    end

    it "validates in multiple contexts of the same subject" do
      expect(SomeModel).to consent_action(:create)
    end

    it "validates the views in which the action is consented" do
      expect(SomeModel).to consent_action(:destroy).with_views(:lol, :self)
    end
  end

  describe "consent_view" do
    it "validates if the subject consents the resulting view given a context" do
      expect(SomeModel).to consent_view(:self, owner_id: 13).to(double(id: 13))
    end

    it "invalidates when conditions don't match" do
      expect(SomeModel).to_not consent_view(:self, owner_id: 14).to(double(id: 13))
    end
  end
end
