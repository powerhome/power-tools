# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::View do
  let(:obj) { double(id: '1235') }

  describe '#conditions' do
    it 'is the callable with the given args' do
      view = Consent::View.new(nil, nil, nil, ->(obj) { obj.id })

      expect(view.conditions(obj)).to eql '1235'
    end
  end
end
