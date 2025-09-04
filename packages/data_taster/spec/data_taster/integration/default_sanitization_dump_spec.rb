# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster Default Sanitization Dump Integration", type: :integration do
  include DatabaseHelper

  let(:test_dump_client) { Mysql2::Client.new(test_dump_database_config) }
  let(:test_dump_db_config) { test_dump_database_config }
  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_dump_export_tables.yml") }

  before do
    # Create and configure the test client
    test_client = Mysql2::Client.new(test_database_config)

    DataTaster.config(
      source_client: test_client,
      working_client: test_dump_client,
      include_insert: true,
      list: [yaml_path]
    )
    create_dump_tables
    setup_source_data
  end

  after do
    cleanup_test_data
  end

  describe "complete data dump workflow" do
    it "creates users and verifies they are properly sanitized" do
      # Run the full sample process using the YAML configuration
      DataTaster.sample!

      # Verify data was copied and sanitized in the dump database
      result = test_dump_client.query("SELECT * FROM users WHERE id = 1").first

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

  def create_dump_tables
    # Create tables in the dump database to match the source database schema
    # The source database tables are created by the schema, but we need to create them in the dump database too

    # Create users table
    test_dump_client.query("CREATE TABLE IF NOT EXISTS users (
      id INT PRIMARY KEY,
      encrypted_password VARCHAR(255),
      ssn VARCHAR(255),
      passport_number VARCHAR(255),
      license_number VARCHAR(255),
      date_of_birth DATE,
      dob DATE,
      notes TEXT,
      body TEXT,
      compensation DECIMAL(10,2),
      income DECIMAL(10,2),
      email VARCHAR(255),
      email2 VARCHAR(255),
      address VARCHAR(255),
      address2 VARCHAR(255),
      created_at DATETIME,
      updated_at DATETIME
    )")

    # Create ar_internal_metadata table (Rails creates with id as primary key)
    test_dump_client.query("CREATE TABLE IF NOT EXISTS ar_internal_metadata (
      id BIGINT AUTO_INCREMENT PRIMARY KEY,
      `key` VARCHAR(255) NOT NULL,
      value TEXT,
      created_at DATETIME,
      updated_at DATETIME
    )")

    # Create schema_migrations table (Rails creates with id as primary key)
    test_dump_client.query("CREATE TABLE IF NOT EXISTS schema_migrations (
      id BIGINT AUTO_INCREMENT PRIMARY KEY,
      version VARCHAR(255) NOT NULL
    )")
  end

  def setup_source_data
    # Insert test data into source database
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    test_client = Mysql2::Client.new(test_database_config)
    test_client.query("INSERT INTO users (id, encrypted_password, ssn, passport_number, license_number, date_of_birth, dob, notes, body, compensation, income, email, email2, address, address2, created_at, updated_at) VALUES (1, 'encrypted123', '123-45-6789', 'P123456789', 'L123456789', '1990-01-01', '1990-01-01', 'Private notes', 'Body text', 50000.00, 60000.00, 'test@example.com', 'test2@example.com', '123 Main St', 'Apt 1', '#{now}', '#{now}')")
  end

  def cleanup_test_data
    # Clean up test data from both databases
    test_client = Mysql2::Client.new(test_database_config)
    test_client.query("DELETE FROM users WHERE id = 1")
    test_dump_client.query("DELETE FROM users WHERE id = 1")
  rescue Mysql2::Error
    # Ignore errors during cleanup
  end
end
