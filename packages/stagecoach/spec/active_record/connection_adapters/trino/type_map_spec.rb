# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::Trino::TypeMap do
  subject(:type_map) { described_class.build }

  describe "string-family types" do
    %w[varchar varchar(255) char char(10) varbinary varbinary(64) uuid].each do |t|
      it "maps #{t} to String" do
        expect(type_map.lookup(t)).to be_a(ActiveModel::Type::String)
      end
    end
  end

  describe "integer types" do
    {
      "tinyint" => 1,
      "smallint" => 2,
      "integer" => 4,
      "int" => 4,
      "bigint" => 8,
    }.each do |trino_type, limit|
      it "maps #{trino_type} to Integer(limit: #{limit})" do
        type = type_map.lookup(trino_type)
        expect(type).to be_a(ActiveModel::Type::Integer)
        expect(type.limit).to eq(limit)
      end
    end
  end

  describe "float types" do
    %w[real double].each do |t|
      it "maps #{t} to Float" do
        expect(type_map.lookup(t)).to be_a(ActiveModel::Type::Float)
      end
    end
  end

  describe "boolean" do
    it "maps boolean" do
      expect(type_map.lookup("boolean")).to be_a(ActiveModel::Type::Boolean)
    end
  end

  describe "date / time / timestamp" do
    it "maps date" do
      expect(type_map.lookup("date")).to be_a(ActiveModel::Type::Date)
    end

    it "maps time" do
      expect(type_map.lookup("time")).to be_a(ActiveModel::Type::Time)
      expect(type_map.lookup("time(3)")).to be_a(ActiveModel::Type::Time)
    end

    it "maps plain timestamp to DateTime" do
      expect(type_map.lookup("timestamp")).to be_a(ActiveModel::Type::DateTime)
      expect(type_map.lookup("timestamp(3)")).to be_a(ActiveModel::Type::DateTime)
    end

    it "maps timestamp with time zone to Stagecoach::Type::TimestampWithZone" do
      expect(type_map.lookup("timestamp with time zone"))
        .to be_a(Stagecoach::Type::TimestampWithZone)
      expect(type_map.lookup("timestamp(3) with time zone"))
        .to be_a(Stagecoach::Type::TimestampWithZone)
    end
  end

  describe "decimal" do
    it "parses precision and scale" do
      type = type_map.lookup("decimal(38, 9)")
      expect(type).to be_a(ActiveModel::Type::Decimal)
      expect(type.precision).to eq(38)
      expect(type.scale).to eq(9)
    end

    it "defaults scale to 0 when missing" do
      type = type_map.lookup("decimal(10)")
      expect(type).to be_a(ActiveModel::Type::Decimal)
      expect(type.precision).to eq(10)
      expect(type.scale).to eq(0)
    end
  end

  describe "json" do
    it "maps json to Stagecoach::Type::Json" do
      expect(type_map.lookup("json")).to be_a(Stagecoach::Type::Json)
    end
  end

  describe "composite types" do
    ["array(varchar)", "map(varchar, integer)", "row(a varchar, b integer)"].each do |t|
      it "returns Unsupported for #{t}" do
        type = type_map.lookup(t)
        expect(type).to be_a(Stagecoach::Type::Unsupported)
        expect { type.cast("anything") }.to raise_error(Stagecoach::UnsupportedTypeError)
      end
    end
  end

  describe "unknown type" do
    it "returns Unsupported and raises on cast" do
      type = type_map.lookup("hyperdrive")
      expect(type).to be_a(Stagecoach::Type::Unsupported)
      expect { type.cast("v") }.to raise_error(Stagecoach::UnsupportedTypeError, /hyperdrive/)
    end
  end

  describe "caching" do
    it "returns the same instance for repeated lookups" do
      a = type_map.lookup("integer")
      b = type_map.lookup("integer")
      expect(a).to equal(b)
    end
  end
end
