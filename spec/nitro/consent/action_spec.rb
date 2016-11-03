require 'spec_helper'

RSpec.describe Consent::Action do
  let(:view1) { Consent::View.new }
  let(:subject) { Consent::Subject.new(nil, nil) }
  let(:options) { { views: [:view1] } }
  let(:action) { Consent::Action.new(:key, 'Label', options) }

  it 'has a key' do
    expect(action.key).to eql :key
  end

  it 'has a label' do
    expect(action.label).to eql 'Label'
  end
end
