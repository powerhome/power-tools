# frozen_string_literal: true

require "spec_helper"
require "data_taster/flavors"
require "active_support/testing/time_helpers"

RSpec.describe DataTaster::Flavors do
  let(:source_client_stub) { double("client") }
  let(:working_client_stub) { double("client") }

  def stub_config(
    months: nil,
    list: "test",
    source_client: source_client_stub,
    working_client: working_client_stub,
    include_insert: false
  )
    allow(DataTaster).to receive(:config).and_return(
      double("config", months: months,
                       list: list,
                       source_client: source_client,
                       working_client: working_client,
                       include_insert: include_insert)
    )
  end

  it "provides the current date" do
    now = Date.current

    travel_to now
    expect(described_class.new.current_date).to eq(now)
  end

  describe "#date" do
    it "returns the configured date, if set" do
      stub_config(months: 1)

      now = Date.current

      travel_to now

      expect(described_class.new.date).to eq((now - 1.month).beginning_of_day.to_formatted_s(:db))
    end

    it "Returns a week ago, if no date given" do
      stub_config
      now = Date.current

      travel_to now

      expect(described_class.new.date).to eq((now - 1.week).beginning_of_day.to_formatted_s(:db))
    end
  end

  it "exposes the source db name" do
    expect(described_class.new.source_db).to eq(source_db_name)
  end

  describe "#default_value_for" do
    it "gives 25 years ago for date_of_birth columns" do
      twenty_five_years_ago_string = (Date.current - 25.years).strftime("%m/%d/%Y")
      expect(described_class.new.default_value_for("date_of_birth"))
        .to eq(twenty_five_years_ago_string)
      expect(described_class.new.default_value_for("other_date_of_birth"))
        .to eq(twenty_five_years_ago_string)
    end

    it "gives all 1's for a social securty number or license" do
      ones = "111111111"
      expect(described_class.new.default_value_for("license")).to eq(ones)
      expect(described_class.new.default_value_for("drivers_license_numver")).to eq(ones)
      expect(described_class.new.default_value_for("ssn")).to eq(ones)
      expect(described_class.new.default_value_for("first_ssn")).to eq(ones)
    end

    it "returns integer 1 for compensation-like column names" do
      expect(described_class.new.default_value_for("compensation")).to eq(1)
      expect(described_class.new.default_value_for("annual_compensation")).to eq(1)
    end

    it "returns the string '1' for other column names" do
      expect(described_class.new.default_value_for("favorite_color")).to eq("1")
    end
  end

  describe "#deprecated_table and #skip_sanitization" do
    it "return the global skip code" do
      flavors = described_class.new
      expect(flavors.deprecated_table).to eq(DataTaster::SKIP_CODE)
      expect(flavors.skip_sanitization).to eq(DataTaster::SKIP_CODE)
    end
  end

  describe "#encryption_error_message" do
    it "mentions attr_encrypted and documentation" do
      msg = described_class.new.encryption_error_message
      expect(msg).to include("attr_encrypted")
      expect(msg).to include("https://github.com/attr-encrypted/attr_encrypted")
    end
  end

  describe "#encrypt" do
    it "calls attr_encrypted_encrypt when the model implements it" do
      model_class = Class.new do
        def attr_encrypted_encrypt(column, value)
          "enc:#{column}:#{value}"
        end
      end

      expect(described_class.new.encrypt(model_class, :token)).to eq("enc:token:1")
    end

    it "calls encrypt when attr_encrypted_encrypt is absent" do
      model_class = Class.new do
        def encrypt(column, value)
          "#{column}=#{value}"
        end
      end

      expect(described_class.new.encrypt(model_class, "ssn")).to eq("ssn=111111111")
    end

    it "raises a helpful error when neither API exists" do
      model_class = Class.new
      expect { described_class.new.encrypt(model_class, :anything) }
        .to raise_error(RuntimeError, /attr_encrypted/)
    end

    it "uses the provided value instead of default_value_for when given" do
      model_class = Class.new do
        def attr_encrypted_encrypt(_column, value)
          value
        end
      end

      expect(described_class.new.encrypt(model_class, :token, "explicit")).to eq("explicit")
    end
  end

  describe "#full_table_dump" do
    it "gives '1 = 1" do
      expect(described_class.new.full_table_dump).to eq("1 = 1")
    end
  end

  describe "#recent_table_updates" do
    it "gives a clause where created or update are greater than the configured date" do
      stub_config(months: 1)
      one_month_ago = (Date.current - 1.month).beginning_of_day.to_formatted_s(:db)
      expect(described_class.new.recent_table_updates)
        .to eq("created_at >= '#{one_month_ago}' OR updated_at >= '#{one_month_ago}'")

      stub_config(months: 2)
      two_months_ago = (Date.current - 2.months).beginning_of_day.to_formatted_s(:db)
      expect(described_class.new.recent_table_updates)
        .to eq("created_at >= '#{two_months_ago}' OR updated_at >= '#{two_months_ago}'")
    end

    it "gives one week ago if no months are configured" do
      stub_config
      one_week_ago = (Date.current - 1.week).beginning_of_day.to_formatted_s(:db)
      expect(described_class.new.recent_table_updates)
        .to eq("created_at >= '#{one_week_ago}' OR updated_at >= '#{one_week_ago}'")
    end
  end

  describe "#recent_ids" do
    it "generates a sub query for the passed table and column name" do
      stub_config

      one_week_ago = (Date.current - 1.week).beginning_of_day.to_formatted_s(:db)
      expected_query = <<~SQL.squish
        (SELECT DISTINCT(author_id)
        FROM #{source_db_name}.comments
        WHERE
        created_at >= '#{one_week_ago}'
        OR
        updated_at >= '#{one_week_ago}')
      SQL
      expect(described_class.new.recent_ids("comments", "author_id")).to eq(expected_query)
    end
  end
end
