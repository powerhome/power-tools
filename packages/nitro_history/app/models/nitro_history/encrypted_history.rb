# frozen_string_literal: true

module NitroHistory
  class EncryptedHistory < ::NitroHistory::History
    attr_encrypted :note, key: NitroConfig.get_deferred!("encryption_key"),
                          encode: true,
                          insecure_mode: true,
                          algorithm: "aes-256-cbc",
                          mode: :single_iv_and_salt

    before_save :clear_plain_note

  private

    def clear_plain_note
      self[:note] = nil
    end
  end
end
