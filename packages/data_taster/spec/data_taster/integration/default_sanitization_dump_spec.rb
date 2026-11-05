# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster Default Sanitization Dump Integration", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_users_dump_tables.yml") }

  before { setup_source_data }

  shared_examples "a complete data dump workflow" do
    it "creates users and verifies they are properly sanitized" do
      DataTaster.sample!

      result = dump_db_client.query("SELECT * FROM users").first

      expect(result).not_to be_nil
      expect(result["id"]).to eq(1)

      expect(result["encrypted_password"]).to be_nil
      expect(result["ssn"]).to eq("111111111")
      expect(result["passport_number"]).to eq("111111111")
      expect(result["license_number"]).to eq("111111111")
      expect(result["notes"]).to eq("Redacted for privacy")
      expect(result["body"]).to eq("Redacted for privacy")
      expect(result["compensation"]).to eq(999_999)
      expect(result["income"]).to eq(999_999)
      expect(result["email"]).to eq("users_1@nitrophrg.com")
      expect(result["email2"]).to eq("users_1_2@nitrophrg.com")
      expect(result["address"]).to eq("1 Disneyland Dr")
      expect(result["address2"]).to eq("Unit M")
      expected_date = Date.current - 29.years
      expect(result["date_of_birth"]).to eq(expected_date)
      expect(result["dob"]).to eq(expected_date)
    end
  end

  context "with Mysql2 clients" do
    before { configure_data_taster(list: [yaml_path]) }

    it_behaves_like "a complete data dump workflow"
  end

  context "with Trilogy clients" do
    before do
      configure_data_taster(
        list: [yaml_path],
        source_client: trilogy_source_db_client,
        target_client: trilogy_dump_db_client
      )
    end

    it_behaves_like "a complete data dump workflow"
  end
end
