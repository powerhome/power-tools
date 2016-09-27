require 'spec_helper'

RSpec.describe Nitro::Consent::Subject do
  subject { Nitro::Consent::Subject.new(nil, nil) }

  describe '#views' do
    it 'starts as the default_views' do
      view = double
      Nitro::Consent.default_views[:view1] = view

      expect(subject.views[:view1]).to be view
    end
  end
end
