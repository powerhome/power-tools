# frozen_string_literal: true

require "rails_helper"

Airplane = Struct.new(:id, :new_record?)

RSpec.describe SimpleTrail do
  let(:airplane) { Airplane.new(10) }

  describe ".record!(source, changes)" do
    subject(:history) { SimpleTrail.record!(airplane, :do_something, { "id" => [nil, 10] }, 23, "Some note") }

    it { is_expected.to be_a SimpleTrail::EntryPresenter }

    it "records the source" do
      expect(history.source_type).to eql "Airplane"
      expect(history.source_id).to eql "10"
    end

    it "records the given history activity" do
      expect(history.activity).to eq "do_something"
      expect(history.source_changes).to eql("id" => [nil, 10])
      expect(history.user_id).to eql(23)
    end

    it "records the note" do
      expect(history.note).to eq "Some note"
    end

    it "encrypts the note" do
      history = SimpleTrail.record!(airplane, :do_something, { "id" => [nil, 10] }, 23, "Some note", encrypted: true)

      expect(history.note).to eq "Some note"
      expect(SimpleTrail::EncryptedHistory.count).to eq 1
      expect(SimpleTrail::EncryptedHistory.last.encrypted_note).not_to be_nil
    end
  end

  describe ".for(source)" do
    it "the history model collection for the given source" do
      history1 = double(activity: "history1")
      history2 = double(activity: "history2")
      allow(SimpleTrail::History).to receive(:for_source)
        .with(airplane)
        .and_return([history1, history2])

      expect(SimpleTrail.for(airplane).map(&:activity)).to match_array %w[history1 history2]
    end

    it "returns history model collection for the given source in natural order" do
      history1 = double(activity: "history1")
      history2 = double(activity: "history2")
      allow(SimpleTrail::History).to receive_message_chain(:for_source, :in_natural_order)
        .and_return([history1, history2])

      expect(SimpleTrail.for(airplane, in_natural_order: true).map(&:activity)).to match_array %w[history1 history2]
    end

    it "returns encrypted history model collection for the given source" do
      history1 = double(activity: "history1")
      history2 = double(activity: "history2")
      allow(SimpleTrail::EncryptedHistory).to receive_message_chain(:for_source)
        .and_return([history1, history2])

      expect(SimpleTrail.for(airplane, encrypted: true).map(&:activity)).to match_array %w[history1 history2]
    end
  end
end
