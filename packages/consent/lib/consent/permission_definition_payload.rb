# frozen_string_literal: true

module Consent
  class PermissionDefinitionPayload
    def self.generate
      subjects = Consent.subjects.sort
      {
        consent_version: Consent::VERSION,
        permissions: subjects.map(&:to_permission_payload),
      }
    end
  end
end
