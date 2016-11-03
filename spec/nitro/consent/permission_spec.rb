require 'spec_helper'

RSpec.describe Consent::Permission do
  let(:action) { double }
  let(:subject) { double }

  describe '#conditions' do
    it 'is the conditions from the view given the view key' do
      view = double
      permission = Consent::Permission.new(subject, action, view)

      expect(view).to receive(:conditions).with('user').and_return 'condition'

      expect(permission.conditions('user')).to eql 'condition'
    end

    it 'is nil when view is not defined' do
      permission = Consent::Permission.new(subject, action, nil)
      expect(permission.conditions).to be_nil
    end
  end
end
