# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::Permission do
  describe '#conditions' do
    it 'is the conditions from the view given the view key' do
      permission = Consent::Permission.new(SomeModel, :destroy, :self)

      expect(permission.conditions(double(id: 13))).to eql(owner_id: 13)
    end

    it 'is nil when view is not defined' do
      permission = Consent::Permission.new(SomeModel, :destroy)

      expect(permission.conditions).to be_nil
    end
  end

  describe '#valid?' do
    it 'is not valid when subject does not exist' do
      permission = Consent::Permission.new(:unexistent, :unexistent)

      expect(permission).to_not be_valid
    end

    it 'is not valid when action does not exist' do
      permission = Consent::Permission.new(:beta, :unexistent)

      expect(permission).to_not be_valid
    end

    it 'is not valid when view is given and does not exist' do
      permission = Consent::Permission.new(SomeModel, :action1, :unexistent)

      expect(permission).to_not be_valid
    end

    it 'is valid without a view' do
      permission = Consent::Permission.new(SomeModel, :action1)

      expect(permission).to be_valid
    end

    it 'is valid without a valid view' do
      permission = Consent::Permission.new(SomeModel, :action1, :lol)

      expect(permission).to be_valid
    end
  end
end
