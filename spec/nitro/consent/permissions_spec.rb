require 'spec_helper'

RSpec.describe Nitro::Consent::Permissions do
  it 'maps a permissions hash to consent subjects' do
    permissions_hash = { some_model: { action1: :view1 } }

    permission = Nitro::Consent.permissions(permissions_hash).first

    expect(permission.subject_key).to be SomeModel
    expect(permission.action_key).to be :action1
    expect(permission.view_key).to be :view1
  end

  it 'maps string view keys' do
    permissions_hash = { 'some_model' => { 'action1' => 'view1' } }

    permission = Nitro::Consent.permissions(permissions_hash).first

    expect(permission.subject_key).to be SomeModel
    expect(permission.action_key).to be :action1
    expect(permission.view_key).to be :view1
  end

  it 'maps symbol subjects' do
    permissions_hash = { features: { beta: true } }

    permission = Nitro::Consent.permissions(permissions_hash).to_a.last

    expect(permission.subject_key).to be :features
    expect(permission.action_key).to be :beta
    expect(permission.view_key).to be nil
  end

  it 'empty view means no permission' do
    permissions_hash = { features: { beta: '' } }

    permissions = Nitro::Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:features)
  end

  it '0 view means no permission' do
    permissions_hash = { features: { beta: 0 } }

    permissions = Nitro::Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:features)
  end

  it '"0" view means no permission' do
    permissions_hash = { features: { beta: '0' } }

    permissions = Nitro::Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:features)
  end

  it 'unexisting view means no permission' do
    permissions_hash = { features: { beta: :something_funky } }

    permissions = Nitro::Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:features)
  end

  it 'does not include permissions not given that do not default' do
    permissions_hash = {}

    permissions = Nitro::Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:features)
  end

  it 'is the default view when no permission' do
    permissions_hash = { some_model: { destroy: '0' } }

    permission = Nitro::Consent.permissions(permissions_hash).first

    expect(permission.view_key).to be :future
  end

  it 'always includes the default permissions' do
    permissions_hash = {}

    permission = Nitro::Consent.permissions(permissions_hash).first

    expect(permission.view_key).to be :future
  end
end
