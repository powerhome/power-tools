# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lumberaxe::Railtie" do
  it "sets the correct log level" do
    expect(Lumberaxe::LogChooser.log_level).to eql(::Rails.application.config.log_level)
  end
end
