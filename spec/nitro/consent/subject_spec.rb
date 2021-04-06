# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::Subject do
  subject { Consent::Subject.new(nil, nil) }

  describe '#views' do
    it 'starts as the default_views' do
      view = double
      Consent.default_views[:view1] = view

      expect(subject.views[:view1]).to be view
    end
  end
end
