# frozen_string_literal: true

require "spec_helper"

# Differences from activerecord-mysql2rgeo-adapter that come from not being a
# separate adapter. Each one is listed in the README's migration guide.
RSpec.describe "Migrating from activerecord-mysql2rgeo-adapter" do
  it "has no mysql2rgeo adapter: database.yml names trilogy or mysql2" do
    expect { ActiveRecord::ConnectionAdapters.resolve("mysql2rgeo") }.to raise_error(ActiveRecord::AdapterNotFound)
  end

  it "reports the driver's adapter name" do
    expect(ActiveRecord::Base.with_connection(&:adapter_name)).to eq(TestDatabase.adapter.capitalize)
  end
end
