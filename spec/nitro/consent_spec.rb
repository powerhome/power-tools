require 'spec_helper'

describe Nitro::Consent do
  describe '.define' do
    it 'creates a new subject with the given key and label' do
      Nitro::Consent.define(:lol_key, 'My Label') {}

      expect(Nitro::Consent.subjects[:lol_key].label).to eql 'My Label'
      expect(Nitro::Consent.subjects[:lol_key].key).to eql :lol_key
    end

    it 'yields a in dsl context' do
      build_context = nil
      Nitro::Consent.define(:lol_key, 'My Label') do
        build_context = self
      end

      expect(build_context).to be_a(Nitro::Consent::DSL)
      expect(build_context.subject).to be Nitro::Consent.subjects[:lol_key]
    end

    it 'yields a in dsl context with defaults' do
      defaults = { views: [:my_view] }

      block = -> (_, __) {}
      expect(Nitro::Consent::DSL).to receive(:build)
        .with(an_instance_of(Nitro::Consent::Subject), defaults, &block)

      Nitro::Consent.define :lol_key, 'My Label', defaults: defaults, &block
    end
  end
end
