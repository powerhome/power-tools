# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::Permission do
  let!(:view) do
    double.tap do |view|
      allow(Consent).to(
        receive(:find_view)
          .with(:subject, :view)
          .and_return(view)
      )
    end
  end

  describe '#conditions' do
    it 'is the conditions from the view given the view key' do
      permission = Consent::Permission.new(:subject, nil, :view)

      expect(view).to receive(:conditions).with('user').and_return 'condition'

      expect(permission.conditions('user')).to eql 'condition'
    end

    it 'is nil when view is not defined' do
      permission = Consent::Permission.new(:subject, :action, nil)

      expect(permission.conditions).to be_nil
    end
  end
end
