# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Consent::Permissions do
  it 'maps a permissions hash to consent subjects' do
    permissions_hash = { some_model: { action1: :view1 } }

    permission = Consent.permissions(permissions_hash).first

    expect(permission.subject_key).to be SomeModel
    expect(permission.action_key).to be :action1
    expect(permission.view_key).to be :view1
  end

  it 'maps a permissions hash to consent subjects with subjects split in' \
    'different definitions' do
    permissions_hash = {
      beta: { lol_til_death: true, request_frustration: true }
    }

    subjects = Consent.permissions(permissions_hash).map(&:subject_key)
    actions = Consent.permissions(permissions_hash).map(&:action_key)

    expect(subjects).to include :beta
    expect(actions).to include :lol_til_death, :request_frustration
  end

  it 'maps string view keys' do
    permissions_hash = { 'some_model' => { 'action1' => 'view1' } }

    permission = Consent.permissions(permissions_hash).first

    expect(permission.subject_key).to be SomeModel
    expect(permission.action_key).to be :action1
    expect(permission.view_key).to be :view1
  end

  it 'maps symbol subjects' do
    permissions_hash = { beta: { lol_til_death: true } }

    permissions = Consent.permissions(permissions_hash).to_a.map(&:subject_key)

    expect(permissions).to include :beta
  end

  it 'empty view means no permission' do
    permissions_hash = { beta: { lol_til_death: '' } }

    permissions = Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:beta)
  end

  it '0 view means no permission' do
    permissions_hash = { beta: { lol_til_death: 0 } }

    permissions = Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:beta)
  end

  it '"0" view means no permission' do
    permissions_hash = { beta: { lol_til_death: '0' } }

    permissions = Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:beta)
  end

  it 'unexisting view means no permission' do
    permissions_hash = { beta: { lol_til_death: :something_funky } }

    permissions = Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:beta)
  end

  it 'does not include permissions not given that do not default' do
    permissions_hash = {}

    permissions = Consent.permissions(permissions_hash)

    expect(permissions.map(&:subject_key)).to_not include(:beta)
  end

  it 'is the default view when no permission' do
    permissions_hash = { some_model: { destroy: '0' } }

    permission = Consent.permissions(permissions_hash).first

    expect(permission.view_key).to be :future
  end

  it 'always includes the default permissions' do
    permissions_hash = {}

    permission = Consent.permissions(permissions_hash).first

    expect(permission.view_key).to be :future
  end
end
