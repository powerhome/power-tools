# frozen_string_literal: true

require "spec_helper"

rails_available = begin
  require "rails"
  require "action_controller/railtie"
  true
rescue LoadError
  false
end

if rails_available
  class WayfindingTestEngine < Rails::Engine
    routes.draw do
      get "/homes/:id", to: ->(_env) { [200, {}, []] }, as: :home
    end
  end
end

RSpec.describe "Rails engine integration" do
  before { skip "Rails is only installed in appraisal bundles" unless rails_available }

  it "resolves paths and URLs from a Rack-callable engine constant" do
    expect(WayfindingTestEngine).to respond_to(:call)

    Wayfinding.register(name: :home, engine: WayfindingTestEngine, helper: :home_path)

    expect(Wayfinding.path_for(:home, 17, tab: "activity")).to eq("/homes/17?tab=activity")
    expect(Wayfinding.url_for(:home, 17, host: "example.test", protocol: "https"))
      .to eq("https://example.test/homes/17")
  end

  it "maps path helpers to URL helpers inside resolver blocks" do
    Wayfinding.register(name: :home, engine: WayfindingTestEngine) do |home_id, **options|
      home_path(home_id, **options)
    end

    expect(Wayfinding.path_for(:home, 17, tab: "activity")).to eq("/homes/17?tab=activity")
    expect(Wayfinding.url_for(:home, 17, host: "example.test", protocol: "https"))
      .to eq("https://example.test/homes/17")
  end
end
