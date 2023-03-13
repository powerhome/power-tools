# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimpleTrail::EncryptedHistory, type: :model do
  let!(:history) { SimpleTrail::EncryptedHistory.create(source_id: 1, source_type: "Test", note: "Note 1") }

  it "saves the encrypted note" do
    history.reload

    expect(history.note).to eql "Note 1"
    expect(history[:encrypted_note]).to_not be_nil
    expect(history[:note]).to be_nil
  end
end
