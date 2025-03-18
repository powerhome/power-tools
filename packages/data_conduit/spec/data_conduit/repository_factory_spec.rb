# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataConduit::RepositoryFactory do
  describe ".create" do
    let(:table_name) { "test_table" }
    let(:conditions) { "status = 'active'" }
    let(:config) { { server: "https://trino.example.com:8443" } }

    it "creates a Trino repository when type is :trino" do
      repository = described_class.create(
        type: :trino,
        table_name:,
        conditions:,
        config:
      )

      expect(repository).to be_a(DataConduit::Adapters::TrinoRepository)
      expect(repository.table_name).to eq(table_name)
      expect(repository.conditions).to eq(conditions)
    end

    it "raises an error for unsupported repository types" do
      expect do
        described_class.create(
          type: :unsupported,
          table_name:
        )
      end.to raise_error(ArgumentError, /Unsupported repository type/)
    end
  end
end
