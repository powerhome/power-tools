require 'spec_helper'

RSpec.describe Nitro::Consent::Action do
  let(:view1) { Nitro::Consent::View.new }
  let(:subject) { Nitro::Consent::Subject.new(nil, nil) }
  let(:options) { { views: [:view1] } }
  let(:action) { Nitro::Consent::Action.new(:key, 'Label', options) }

  it 'has a key' do
    expect(action.key).to eql :key
  end

  it 'has a label' do
    expect(action.label).to eql 'Label'
  end
end
