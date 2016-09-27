require 'spec_helper'

RSpec.describe Nitro::Consent::Permission do
  let(:subject) { double }
  let(:permission) { Nitro::Consent::Permission.new(subject, :save, :recent) }

  describe '#conditions' do
    it 'is the conditions from the view given the view key' do
      user = 'user'
      view = double

      allow(subject).to receive(:view_for).with(:save, :recent).and_return view
      expect(view).to receive(:conditions).with(user).and_return 'condition'

      expect(permission.conditions(user)).to eql 'condition'
    end

    it 'is nil when view is not defined' do
      allow(subject).to receive(:view_for).and_return nil

      expect(permission.conditions).to be_nil
    end
  end
end
