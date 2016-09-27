require 'spec_helper'

RSpec.describe Nitro::Consent::Action do
  let(:view1) { Nitro::Consent::View.new }
  let(:subject) { Nitro::Consent::Subject.new(nil, nil) }
  let(:options) { { views: [:view1] } }
  let(:action) { Nitro::Consent::Action.new(subject, :key, 'Label', options) }

  it 'has a key' do
    expect(action.key).to eql :key
  end

  it 'has a subject' do
    expect(action.subject).to eql subject
  end

  it 'has a label' do
    expect(action.label).to eql 'Label'
  end

  describe '#views' do
    it 'is the collection of existing views in the subject context' do
      subject.views[:view1] = view1
      expect(action.views).to eql [view1]
    end

    it 'excludes views that do not exist in the subject' do
      subject.views.delete(:view1)
      expect(action.views).to_not include view1
    end
  end
end
