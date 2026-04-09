# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DataTaster Sanitize Selected Tables Integration", type: :integration do
  include DatabaseHelper

  let(:yaml_path) { File.join(__dir__, "..", "..", "fixtures", "full_users_dump_tables.yml") }

  before do
    DataTaster.config(
      source_client: dump_db_client,
      working_client: dump_db_client,
      include_insert: true,
      list: [yaml_path]
    )
    dump_db_client.query("TRUNCATE TABLE users")
    insert_user
  end

  it "sanitizes existing rows without TRUNCATE/INSERT copy" do
    DataTaster.sanitize_selected_tables!

    result = dump_db_client.query("SELECT * FROM users").first

    expect(result).not_to be_nil
    expect(result["id"]).to eq(1)
    expect(result["encrypted_password"]).to be_nil
    expect(result["ssn"]).to eq("111111111")
    expect(result["email"]).to eq("users_1@nitrophrg.com")
  end

private

  def insert_user
    now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    dump_db_client.query(<<-SQL.squish)
      INSERT INTO users (id, encrypted_password, ssn, passport_number, license_number, date_of_birth, dob, notes, body,
       compensation, income, email, email2, address, address2, created_at, updated_at)
      VALUES (1, 'encrypted123', '123-45-6789', 'P123456789', 'L123456789', '1990-01-01', '1990-01-01',
        'Private notes', 'Body text', 50000.00, 60000.00, 'test@example.com', 'test2@example.com', '123 Main St',
        'Apt 1', '#{now}', '#{now}')
    SQL
  end
end
