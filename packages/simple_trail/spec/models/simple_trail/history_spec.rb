# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimpleTrail::History, type: :model do
  let!(:note_1) { SimpleTrail::History.create(source_id: 1, source_type: "Test", note: "Note 1") }
  let!(:note_2) { SimpleTrail::History.create(source_id: 2, source_type: "Test", note: "Note 2") }

  it "serializes the source changes" do
    history = SimpleTrail::History.create(source_changes: { "id" => [nil, 10] })

    history.reload

    expect(history.source_changes).to eql("id" => [nil, 10])
  end

  describe ".in_natural_order" do
    it "returns history collection in natural order" do
      expect(SimpleTrail::History.in_natural_order).to eq([note_1, note_2])
    end
  end

  describe ".for_source" do
    it "returns history collection in natural order" do
      Test = Struct.new(:id)
      expect(SimpleTrail::History.for_source(Test.new(1))).to eq([note_1])
    end
  end

  it "returns history collection in reverse chronological order" do
    expect(SimpleTrail::History.all).to eq([note_2, note_1]) # applies default_scope
  end
end