# frozen_string_literal: true

require "rails_helper"

Test = Struct.new(:id)

RSpec.describe CamelTrail::History do
  let!(:note_one) { CamelTrail::History.create(source_id: 1, source_type: "Test", note: "Note 1") }
  let!(:note_two) { CamelTrail::History.create(source_id: 2, source_type: "Test", note: "Note 2") }

  it "serializes the source changes" do
    history = CamelTrail::History.create(source_changes: { "id" => [nil, 10] })

    history.reload

    expect(history.source_changes).to eql("id" => [nil, 10])
  end

  describe ".in_natural_order" do
    it "returns history collection in natural order" do
      expect(CamelTrail::History.in_natural_order).to eq([note_one, note_two])
    end
  end

  describe ".for_source" do
    it "returns history collection in natural order" do
      expect(CamelTrail::History.for_source(Test.new(1))).to eq([note_one])
    end
  end

  it "returns history collection in reverse chronological order" do
    expect(CamelTrail::History.all).to eq([note_two, note_one]) # applies default_scope
  end
end
