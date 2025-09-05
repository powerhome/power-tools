# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster Default Sanitization Dump Integration", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_dump_export_tables.yml") }

  before do
    DataTaster.config(
      source_client: source_db_client,
      working_client: dump_db_client,
      include_insert: true,
      list: [yaml_path]
    )
    setup_source_data
  end

  describe "complete data dump workflow" do
    it "creates users and verifies they are properly sanitized" do
      # Run the full sample process using the YAML configuration
      DataTaster.sample!

      # Verify data was copied and sanitized in the dump database
      result = dump_db_client.query("SELECT * FROM users WHERE id = 1").first

      expect(result).not_to be_nil
      expect(result["id"]).to eq(1)

      # Verify default sanitization patterns were applied
      expect(result["encrypted_password"]).to be_nil
      expect(result["ssn"]).to eq("111111111")
      expect(result["passport_number"]).to eq("111111111")
      expect(result["license_number"]).to eq("111111111")
      expect(result["notes"]).to eq("Redacted for privacy")
      expect(result["body"]).to eq("Redacted for privacy")
      expect(result["compensation"]).to eq(999_999)
      expect(result["income"]).to eq(999_999)

      # Verify email sanitization
      expect(result["email"]).to eq("users_1@nitrophrg.com")
      expect(result["email2"]).to eq("users_1_2@nitrophrg.com")

      # Verify address sanitization
      expect(result["address"]).to eq("1 Disneyland Dr")
      expect(result["address2"]).to eq("Unit M")

      # Verify date sanitization (should be 29 years ago from current date)
      expected_date = Date.current - 29.years
      expect(result["date_of_birth"]).to eq(expected_date)
      expect(result["dob"]).to eq(expected_date)
    end
  end

private

  def setup_source_data
    # Insert test data into source database
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    insert_user_sql = <<-SQL.squish
      INSERT INTO users (id, encrypted_password, ssn, passport_number, license_number, date_of_birth, dob, notes, body,
       compensation, income, email, email2, address, address2, created_at, updated_at)
      VALUES (1, 'encrypted123', '123-45-6789', 'P123456789', 'L123456789', '1990-01-01', '1990-01-01',
        'Private notes', 'Body text', 50000.00, 60000.00, 'test@example.com', 'test2@example.com', '123 Main St',
        'Apt 1', '#{now}', '#{now}')
    SQL
    source_db_client.query(insert_user_sql)
  end
end
