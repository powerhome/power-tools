# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::PermissionDefinitionPayload do
  it "returns the correct permission definitions payload" do
    payload = Consent::PermissionDefinitionPayload.generate
    expect(payload).to eq({
                            consent_version: Consent::VERSION,
                            permissions: Consent.subjects.map(&:to_permission_payload),
                          })
  end
end