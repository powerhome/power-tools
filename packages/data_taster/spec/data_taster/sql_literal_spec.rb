# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::SqlLiteral do
  let(:client) do
    double("client").tap do |stub|
      allow(stub).to receive(:escape) { |value| value.gsub("'", "''") }
    end
  end

  describe ".format" do
    it "emits a quoted string for ASCII_8BIT JSON column values" do
      json = '{"key":"value"}'.b

      expect(described_class.format(client, json, column_type: "json")).to eq('\'{"key":"value"}\'')
    end

    it "emits a hex literal for ASCII_8BIT blob column values" do
      binary = "\x00\x01\xff".b

      expect(described_class.format(client, binary, column_type: "blob")).to eq("X'0001ff'")
    end

    it "emits a hex literal for ASCII_8BIT values that are not valid UTF-8 when type is unknown" do
      binary = "\xff\xfe".b

      expect(described_class.format(client, binary)).to eq("X'fffe'")
    end

    it "emits a quoted string for ASCII_8BIT values that are valid UTF-8 when type is unknown" do
      json = '{"a":1}'.b

      expect(described_class.format(client, json)).to eq('\'{"a":1}\'')
    end

    it "emits a quoted string for UTF-8 strings" do
      expect(described_class.format(client, "hello")).to eq("'hello'")
    end
  end
end
