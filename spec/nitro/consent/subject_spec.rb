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

  describe '#view_for' do
    let(:all_view) { double }
    let(:none_view) { double }
    let(:action) { double(view_keys: [:all, :none, :some], default_view: :some) }

    before do
      subject.views[:all] = all_view
      subject.views[:none] = none_view
      subject.actions << action
    end

    it 'is the view with the given key' do
      expect(subject.view_for(action, :all)).to be all_view
    end
  end
end
