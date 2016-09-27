require 'spec_helper'

RSpec.describe Nitro::Consent::Ability do
  it 'it authorizes symbol permissions' do
    subject = Nitro::Consent::Subject.new(:features, nil)
    action = Nitro::Consent::Action.new(nil, :some_crazy_feature)
    permission = Nitro::Consent::Permission.new(subject, action)

    expect(Nitro::Consent).to receive(:permissions).and_return [permission]
    ability = Nitro::Consent::Ability.new(features: { some_crazy_feature: '1' })

    expect(ability).to be_able_to(:some_crazy_feature, :features)
  end

  it 'it authorizes model permissions' do
    subject = Nitro::Consent::Subject.new(SomeModel, nil)
    action = Nitro::Consent::Action.new(nil, :some_crazy_feature)
    permission = Nitro::Consent::Permission.new(subject, action)

    expect(Nitro::Consent).to receive(:permissions).and_return [permission]
    ability = Nitro::Consent::Ability.new(feature: { some_crazy_feature: '1' })

    expect(ability).to be_able_to(:some_crazy_feature, SomeModel)
  end

  it 'adds view conditions to cancan conditions' do
    subject = Nitro::Consent::Subject.new(SomeModel, nil)
    action = Nitro::Consent::Action.new(nil, :some_crazy_feature)
    view = double(Nitro::Consent::View, conditions: { name: 'lol' })
    permission = Nitro::Consent::Permission.new(subject, action, view)

    expect(Nitro::Consent).to receive(:permissions).and_return [permission]
    ability = Nitro::Consent::Ability.new(feature: { some_crazy_feature: '1' })

    expect(ability).to be_able_to(:some_crazy_feature, SomeModel)

    expect(ability).to be_able_to(:some_crazy_feature, SomeModel.new('lol'))
    expect(ability).to_not be_able_to(:some_crazy_feature, SomeModel.new('nop'))
  end
end
