# frozen_string_literal: true

require "spec_helper"

describe Consent do
  describe ".define" do
    it "creates a new subject with the given key and label" do
      Consent.define(:lol_key, "My Label") {}

      expect(Consent.subjects.last.label).to eql "My Label"
      expect(Consent.subjects.last.key).to eql :lol_key
    end

    it "yields a in dsl context" do
      build_context = nil
      Consent.define(:lol_key, "My Label") do
        build_context = self
      end

      expect(build_context).to be_a(Consent::DSL)
      expect(build_context.subject).to be Consent.subjects.last
    end

    it "yields a in dsl context with defaults" do
      defaults = { views: [:my_view] }

      block = ->(*) {}
      expect(Consent::DSL).to receive(:build)
        .with(an_instance_of(Consent::Subject), defaults, &block)

      Consent.define :lol_key, "My Label", defaults: defaults, &block
    end

    it "allows a subject to have multiple action definitions" do
      Consent.define(:lol_key, "LOL at work") {}
      Consent.define(:lol_key, "LOL at home") {}

      keys = Consent.subjects.map(&:key)
      labels = Consent.subjects.map(&:label)

      expect(labels).to include "LOL at work", "LOL at home"
      expect(keys).to include :lol_key
    end
  end

  describe ".subjects_checksum" do
    it "returns SHA256 hexdigest of permission definitions" do
      checksum = Consent.subjects_checksum
      subjects_checksum = Digest::SHA256.hexdigest(Consent.subjects.sort.map(&:to_permission_payload).to_json)

      expect(checksum).to eq(subjects_checksum)
    end

    it "returns different checksum when content changes" do
      subjects_checksum1 = Consent.subjects_checksum
      Consent.subjects.last.actions << Consent::Action.new(Consent.subjects.last, :new_action, "New Action")
      subjects_checksum2 = Consent.subjects_checksum

      expect(subjects_checksum1).not_to eq(subjects_checksum2)
    end
  end
end
