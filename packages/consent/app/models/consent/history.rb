# frozen_string_literal: true

module Consent
  class History < ::Consent::ApplicationRecord
    include Consent::SubjectCoder::Model

    enum :command, { grant: "grant", revoke: "revoke" }

    validates :subject, presence: true
    validates :action, presence: true
    validates :view, presence: true
    validates :command, presence: true

    def self.record(command, permission)
      create!(
        **permission.slice(:role_id, :subject, :action, :view),
        command: command.to_s
      )
    end
  end
end
