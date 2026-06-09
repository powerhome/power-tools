# frozen_string_literal: true

module Consent
  class PermissionDefinitionPayload
    def self.generate
      {
        consent_version: Consent::VERSION,
        permissions: Consent.subjects.sort_by(&:key).map(&:to_permission_payload),
      }
    end
  end
end
