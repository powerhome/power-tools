# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wayfinding::Destination do
  describe "resolution" do
    it "instance_execs a block against the engine's url helpers" do
      Wayfinding.register(name: :lead_source, engine: -> { FakeEngine }) do |lead_source|
        lead_source_path(lead_source)
      end

      expect(Wayfinding.path_for(:lead_source, 9)).to eq("/lead_sources/9")
    end

    it "calls a block plainly when no engine is given" do
      Wayfinding.register(name: :external) { |id| "https://elsewhere.test/#{id}" }

      expect(Wayfinding.path_for(:external, 4)).to eq("https://elsewhere.test/4")
      expect(Wayfinding.url_for(:external, 4)).to eq("https://elsewhere.test/4")
    end
  end

  describe "metadata" do
    subject(:destination) { Wayfinding.fetch(:report) }

    it "stores every field without interpretation" do
      label = -> { "Installer Pay" }
      Wayfinding.register(
        name: :report, engine: -> { FakeEngine }, helper: :installer_pay_reports_path,
        label: label, foo: "bar"
      )

      expect(destination[:label]).to be(label)
      expect(destination[:foo]).to eq("bar")
    end

    it "resolves any callable field lazily through value_for" do
      resolved = false
      Wayfinding.register(
        name: :report, engine: -> { FakeEngine }, helper: :installer_pay_reports_path,
        foo: -> {
          resolved = true
          "bar"
        }
      )

      expect(resolved).to be(false)
      expect(destination.value_for(:foo)).to eq("bar")
      expect(resolved).to be(true)
    end

    it "resolves a callable subject lazily, only when read" do
      resolved = false
      Wayfinding.register(
        name: :report, engine: -> { FakeEngine }, helper: :installer_pay_reports_path,
        action: :view, subject: -> {
          resolved = true
          Object
        }
      )

      expect(resolved).to be(false)
      expect(destination.subject).to eq(Object)
      expect(resolved).to be(true)
    end
  end

  describe "#[]" do
    subject(:destination) { Wayfinding.fetch(:report) }

    before do
      Wayfinding.register(
        name: :report, engine: -> { FakeEngine }, helper: :installer_pay_reports_path,
        label: "Installer Pay", data: { confirm: "Are you sure?" }, foo: "bar"
      )
    end

    it "reads arbitrary attributes" do
      expect(destination[:data]).to eq(confirm: "Are you sure?")
      expect(destination[:foo]).to eq("bar")
      expect(destination[:label]).to eq("Installer Pay")
    end

    it "returns nil for anything unregistered" do
      expect(destination[:nope]).to be_nil
    end
  end
end
