# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lumberaxe, type: :request do
  subject do
    post "/campgrounds", params: { campground: { name: "Cloudland Canyon" }, format: :json }
  end

  it "contains key/value pairs" do
    expect { subject }.to output(/"message":/).to_stdout_from_any_process
  end

  it "logs HTTP requests" do
    expect { subject }.to output(/"method":"POST","path":"\/campgrounds"/).to_stdout_from_any_process
  end

  it "logs any params" do
    expect { subject }.to output(/"params":{"campground":{"name":"Cloudland Canyon"}/).to_stdout_from_any_process
  end

  it "logs DB requests" do
    expect { subject }.to output(/INSERT INTO/).to_stdout_from_any_process
  end

  it "logs error response" do
    expect { post "/campgrounds", params: { campground: { name: nil } } }.to output(/"status":422/).to_stdout_from_any_process
  end
end
