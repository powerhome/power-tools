# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edgestitch::Exporter do
  let(:dump) { double(Edgestitch::Mysql::Dump, export_tables: "tables sql", export_migrations: "migrations sql") }

  it "exports the tables of models owned by the engine" do
    exporter = Edgestitch::Exporter.new(Sales::Engine)
    output = StringIO.new

    exporter.export(dump, io: output)

    expect(output.string).to eql "tables sql\n\nmigrations sql\n"
  end

  it "selects the tables belonging to the given engine" do
    exporter = Edgestitch::Exporter.new(Sales::Engine)

    expect(exporter.tables).to match_array %w[sales_prices]
  end

  it "includes extra tables owned by the engine" do
    exporter = Edgestitch::Exporter.new(Payroll::Engine)

    expect(exporter.tables).to match_array %w[payroll_salaries taggings tags]
  end

  it "includes only migrations inside that engine" do
    exporter = Edgestitch::Exporter.new(Payroll::Engine)

    expect(exporter.migrations).to match_array [20_221_219_195_431, 20_221_219_231_318, 20_221_219_231_320,
                                                20_221_219_231_322, 20_221_219_231_323, 20_221_219_231_324]
  end
end
