# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wayfinding::RSpecHelpers do
  describe "#stub_destination" do
    it "registers a fixed destination with metadata" do
      stub_destination(:home, "/homes/1", label: "Home")

      expect(Wayfinding.path_for(:home)).to eq("/homes/1")
      expect(Wayfinding.url_for(:home)).to eq("/homes/1")
      expect(Wayfinding.fetch(:home)[:label]).to eq("Home")
    end

    it "registers a block destination" do
      stub_destination(:home) { |home_id, tab:| "/homes/#{home_id}?tab=#{tab}" }

      expect(Wayfinding.path_for(:home, 17, tab: "activity")).to eq("/homes/17?tab=activity")
    end
  end

  context "when an example changes the registry", order: :defined do
    before(:context) do
      Wayfinding.reset!
      Wayfinding.define_kind(:baseline, requires: [:label])
      Wayfinding.register(name: :baseline, kind: :baseline, label: "Baseline") { "/baseline" }
    end

    after(:context) { Wayfinding.reset! }

    it "allows temporary destinations and kinds" do
      Wayfinding.define_kind(:temporary)
      stub_destination(:temporary, "/temporary", kind: :temporary)

      expect(Wayfinding.registered_names).to contain_exactly(:baseline, :temporary)
      expect(Wayfinding.kinds).to include(:baseline, :temporary)
    end

    it "restores destinations and kinds before the next example" do
      expect(Wayfinding.registered_names).to eq([:baseline])
      expect(Wayfinding.kinds.keys).to eq([:baseline])
    end
  end
end
