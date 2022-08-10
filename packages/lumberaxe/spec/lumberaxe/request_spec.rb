# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Lumberaxe integration" do
  it "prints to stdout" do
    expect { print("foo") }.to output(/foo/).to_stdout
  end
end
