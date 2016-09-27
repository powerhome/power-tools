require 'spec_helper'

RSpec.describe Nitro::Consent::Subject do
  subject { Nitro::Consent::Subject.new(nil, nil, nil) }

  describe '#views' do
    it 'starts as the default_views' do
      view = double
      Nitro::Consent.default_views[:view1] = view

      expect(subject.views[:view1]).to be view
    end
  end

  describe '#conditions' do
    it 'is the conditions from the view given the view key' do
      user = 'user'
      half_thing_view = double(conditions: nil)

      subject.views[:half_thing] = half_thing_view
      expect(half_thing_view).to receive(:conditions).with(user).and_return('conditions')

      expect(subject.conditions(:half_thing, user)).to eql 'conditions'
    end

    it 'is nil when view is not defined' do
      expect(subject.conditions(:whatever)).to be_nil
    end
  end
end
