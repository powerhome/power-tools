# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::Ability do
  let(:user) { double(id: 1) }
  let(:ability) { Consent::Ability.new(user) }

  it 'it authorizes symbol permissions' do
    ability.consent subject: :beta, action: :lol_til_death

    expect(ability).to be_able_to(:lol_til_death, :beta)
  end

  it 'it authorizes model permissions' do
    ability.consent subject: SomeModel, action: :action1

    expect(ability).to be_able_to(:action1, SomeModel)
    expect(ability).to be_able_to(:action1, SomeModel.new)
  end

  it 'adds view conditions to cancan conditions' do
    ability.consent subject: SomeModel, action: :action1, view: :lol

    expect(ability).to be_able_to(:action1, SomeModel)

    expect(ability).to be_able_to(:action1, SomeModel.new('lol'))
    expect(ability).to_not be_able_to(:action1, SomeModel.new('nop'))
  end

  it 'no permission is consented unless explicitly consented' do
    expect(ability).to_not be_able_to(:action1, SomeModel)
  end

  it 'has the default view consented when defined' do
    past = SomeModel.new(nil, Date.new - 10)
    future = SomeModel.new(nil, Date.new + 10)
    expect(ability).to be_able_to(:destroy, future)
    expect(ability).to_not be_able_to(:destroy, past)
  end

  it 'cannot perform action when instance condition forbids' do
    past = SomeModel.new(nil, Date.new - 10)

    expect(ability).to_not be_able_to(:destroy, past)
  end

  it 'contextualizes the view/action in the subject definition' do
    ability.consent subject: SomeModel, action: :create, view: :lol
    ability.consent subject: SomeModel, action: :destroy, view: :lol

    create_rule = ability.send(:relevant_rules, :create, SomeModel).first
    destroy_rule = ability.send(:relevant_rules, :destroy, SomeModel).first

    expect(create_rule.conditions).to eql(name: 'ROFL')
    expect(destroy_rule.conditions).to eql(name: 'lol')
  end
end
