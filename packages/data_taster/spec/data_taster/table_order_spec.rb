# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::TableOrder do
  before do
    configure_data_taster
    allow(DataTaster).to receive(:confection).and_return(confection)
  end

  def order(table_names)
    described_class.new(table_names).to_a
  end

  context "when no select: clause names another table" do
    let(:confection) { { "accounts" => "1 = 1", "users" => "id = 1" } }

    it "keeps the order it was given" do
      expect(order(%w[users accounts projects])).to eq(%w[users accounts projects])
    end
  end

  context "when a select: clause names a table without a database" do
    let(:confection) do
      {
        "calls" => "phone_id IN (SELECT id FROM phones)",
        "phone_numbers" => "id IN (SELECT phone_number_id FROM users)",
        "phones" => "phone_number_id IN (SELECT id FROM phone_numbers)",
      }
    end

    it "puts the named tables first, and the rest in the order given" do
      expect(order(%w[accounts calls phone_numbers phones users])).to eq(%w[accounts users phone_numbers phones calls])
    end
  end

  context "when the select: clause names the table with a database" do
    let(:confection) { { "accounts" => "user_id IN (SELECT id FROM source.users)" } }

    it "keeps the order it was given" do
      expect(order(%w[accounts users])).to eq(%w[accounts users])
    end
  end

  context "when select: clauses name each other" do
    let(:confection) do
      {
        "accounts" => "id IN (SELECT account_id FROM users)",
        "users" => "account_id IN (SELECT id FROM accounts)",
      }
    end

    it "keeps those tables in the order given" do
      expect(order(%w[accounts projects users])).to eq(%w[accounts users projects])
    end
  end
end
