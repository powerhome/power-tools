# frozen_string_literal: true

require 'spec_helper'

describe Consent do
  describe '.define' do
    it 'creates a new subject with the given key and label' do
      Consent.define(:lol_key, 'My Label') {}

      expect(Consent.subjects.last.label).to eql 'My Label'
      expect(Consent.subjects.last.key).to eql :lol_key
    end

    it 'yields a in dsl context' do
      build_context = nil
      Consent.define(:lol_key, 'My Label') do
        build_context = self
      end

      expect(build_context).to be_a(Consent::DSL)
      expect(build_context.subject).to be Consent.subjects.last
    end

    it 'yields a in dsl context with defaults' do
      defaults = { views: [:my_view] }

      block = ->(_, __) {}
      expect(Consent::DSL).to receive(:build)
        .with(an_instance_of(Consent::Subject), defaults, &block)

      Consent.define :lol_key, 'My Label', defaults: defaults, &block
    end

    it 'allows a subject to have multiple action definitions' do
      Consent.define(:lol_key, 'LOL at work') {}
      Consent.define(:lol_key, 'LOL at home') {}

      keys = Consent.subjects.map(&:key)
      labels = Consent.subjects.map(&:label)

      expect(labels).to include 'LOL at work', 'LOL at home'
      expect(keys).to include :lol_key
    end
  end
end
