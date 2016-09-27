require 'spec_helper'

RSpec.describe Nitro::Consent::Ability do
  it 'it authorizes symbol permissions' do
    ability = Nitro::Consent::Ability.new(features: { beta: '1' })

    expect(ability).to be_able_to(:beta, :features)
  end

  it 'it authorizes model permissions' do
    ability = Nitro::Consent::Ability.new(some_model: { action1: '1' })

    expect(ability).to be_able_to(:action1, SomeModel)
    expect(ability).to be_able_to(:action1, SomeModel.new)
  end

  it 'adds view conditions to cancan conditions' do
    ability = Nitro::Consent::Ability.new(some_model: { action1: :lol })

    expect(ability).to be_able_to(:action1, SomeModel)

    expect(ability).to be_able_to(:action1, SomeModel.new('lol'))
    expect(ability).to_not be_able_to(:action1, SomeModel.new('nop'))
  end

  it 'empty view means no permission' do
    ability = Nitro::Consent::Ability.new(some_model: { action1: '' })

    expect(ability).to_not be_able_to(:action1, SomeModel)
  end

  it '0 view means no permission' do
    ability = Nitro::Consent::Ability.new(some_model: { action1: 0 })

    expect(ability).to_not be_able_to(:action1, SomeModel)
  end

  it '"0" view means no permission' do
    ability = Nitro::Consent::Ability.new(some_model: { action1: '0' })

    expect(ability).to_not be_able_to(:action1, SomeModel)
  end
end
