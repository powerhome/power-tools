# frozen_string_literal: true

RSpec.describe "Test database connection" do
  it "connects through the driver selected by DB_ADAPTER" do
    adapter_name = ActiveRecord::Base.with_connection(&:adapter_name)

    expect(adapter_name.downcase).to eq(TestDatabase.adapter)
  end
end
