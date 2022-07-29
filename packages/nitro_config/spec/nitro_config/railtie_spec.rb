# frozen_string_literal: true

require "rails_helper"

RSpec.describe "NitroConfig::Railtie" do
  it "loads the configuration by the current rails env on load" do
    expect(NitroConfig.get("env_name")).to eql Rails.env
    expect(NitroConfig.get("key/nested/value")).to eql "Hello World"
  end
end
