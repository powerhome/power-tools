# frozen_string_literal: true

# rubocop:disable Rails/SaveBang

require "spec_helper"
require "aether_observatory/rspec/event_helper"

class FakeEvent < AetherObservatory::EventBase
  attribute :message

  event_name "fake.event"
end

RSpec.describe "AetherObservatory Rspec event matcher" do
  include AetherObservatory::Rspec::EventHelper

  describe "creat_event matcher" do
    it "works with the event helper" do
      expect do
        FakeEvent.create
      end.to create_event(FakeEvent)
    end

    it "works when negated" do
      expect { nil }.to_not create_event(FakeEvent)
    end

    it "matchers attributes" do
      expect { FakeEvent.create(message: "Bonjour") }.to_not create_event(FakeEvent, message: "Bonsoir")
    end

    it "matchers attributes negating" do
      expect { FakeEvent.create(message: "Bonsoir") }.to create_event(FakeEvent, message: "Bonsoir")
    end
  end
end

# rubocop:enable Rails/SaveBang
