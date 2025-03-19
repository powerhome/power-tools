# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataConduit::DataWarehouseRepository do
  let(:test_repository_class) do
    Class.new do
      include DataConduit::DataWarehouseRepository

      attr_reader :table_name, :conditions, :config

      def initialize(table_name, conditions = nil, config = {})
        @table_name = table_name
        @conditions = conditions
        @config = config
      end

      # Expose protected methods for testing
      def test_transform_response(result_data, result_columns)
        transform_response(result_data, result_columns)
      end

      def test_transform_key(key)
        transform_key(key)
      end

      def test_transform_row(row)
        transform_row(row)
      end
    end
  end

  let(:repository) { test_repository_class.new("test_table", nil, config) }
  let(:config) { {} }

  describe "#transform_response" do
    let(:result_data) { [[1, "test", 100.5]] }
    let(:result_columns) { [{ "name" => "ID" }, { "name" => "NAME" }, { "name" => "AMOUNT" }] }

    it "transforms data with default options" do
      result = repository.test_transform_response(result_data, result_columns)
      expect(result).to eq([{ "ID" => 1, "NAME" => "test", "AMOUNT" => 100.5 }])
    end

    it "returns an empty array for nil data" do
      expect(repository.test_transform_response(nil, result_columns)).to eq([])
    end

    it "returns an empty array for empty data" do
      expect(repository.test_transform_response([], result_columns)).to eq([])
    end
  end

  describe "#transform_key" do
    context "with default options" do
      it "returns the key as a string" do
        expect(repository.test_transform_key("COLUMN_NAME")).to eq("COLUMN_NAME")
        expect(repository.test_transform_key(:column_name)).to eq("column_name")
      end
    end

    context "with symbol keys" do
      let(:config) { { transform_options: { keys: :symbol } } }

      it "returns the key as a symbol" do
        expect(repository.test_transform_key("COLUMN_NAME")).to eq(:COLUMN_NAME)
        expect(repository.test_transform_key(:column_name)).to eq(:column_name)
      end
    end

    context "with key transformation" do
      let(:config) do
        {
          transform_options: {
            transform_keys: ->(key) { key.to_s.downcase },
          },
        }
      end

      it "applies the transformation to the key" do
        expect(repository.test_transform_key("COLUMN_NAME")).to eq("column_name")
        expect(repository.test_transform_key(:COLUMN_NAME)).to eq("column_name")
      end
    end
  end

  describe "#transform_row" do
    let(:row) { { "USER_ID" => 1, "AMOUNT" => "  100.50  " } }

    context "with default options" do
      it "doesn't change the row" do
        expect(repository.test_transform_row(row)).to eq(row)
      end
    end

    context "with key transformation" do
      let(:config) do
        {
          transform_options: {
            transform_keys: ->(key) { key.downcase },
          },
        }
      end

      it "transforms the keys" do
        expect(repository.test_transform_row(row)).to eq({
                                                           "user_id" => 1,
                                                           "amount" => "  100.50  ",
                                                         })
      end
    end

    context "with value transformation" do
      let(:config) do
        {
          transform_options: {
            transform_values: ->(value) { value.is_a?(String) ? value.strip : value },
          },
        }
      end

      it "transforms the values" do
        expect(repository.test_transform_row(row)).to eq({
                                                           "USER_ID" => 1,
                                                           "AMOUNT" => "100.50",
                                                         })
      end
    end

    context "with combined transformations" do
      let(:config) do
        {
          transform_options: {
            keys: :symbol,
            transform_keys: ->(key) { key.downcase },
            transform_values: ->(value) { value.is_a?(String) ? value.strip : value },
          },
        }
      end

      it "applies all transformations" do
        expect(repository.test_transform_row(row)).to eq({
                                                           user_id: 1,
                                                           amount: "100.50",
                                                         })
      end
    end
  end
  describe "#validate_table_name" do
    let(:validation_test_class) do
      Class.new do
        include DataConduit::DataWarehouseRepository

        # Override initialize to avoid argument errors
        def initialize
        end

        # Expose protected method for testing
        def test_validate_table_name(table_name)
          validate_table_name(table_name)
        end
      end
    end

    subject(:validator) { validation_test_class.new }

    it "accepts valid table names" do
      valid_names = ["table", "schema.table", "db_name", "table_name_with_underscores", "t1"]

      valid_names.each do |name|
        expect { validator.test_validate_table_name(name) }.not_to raise_error
      end
    end

    it "rejects nil or empty table names" do
      expect { validator.test_validate_table_name(nil) }.to raise_error(ArgumentError, /cannot be blank/)
      expect { validator.test_validate_table_name("") }.to raise_error(ArgumentError, /cannot be blank/)
    end

    it "rejects invalid table name formats" do
      invalid_names = ["table-name", "table name", "table;drop", "table*name"]

      invalid_names.each do |name|
        expect { validator.test_validate_table_name(name) }.to raise_error(ArgumentError, /Invalid table name format/)
      end
    end
  end
end
