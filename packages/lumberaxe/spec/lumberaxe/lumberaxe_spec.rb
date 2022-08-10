# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lumberaxe, type: :request do
  subject do
    post "/campgrounds", params: { campground: { name: "Cloudland Canyon" } }
  end

  it "logs creation" do
    expect { subject }.to output(/foo/).to_stdout
  end
end
