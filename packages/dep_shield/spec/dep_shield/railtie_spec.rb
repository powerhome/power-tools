# frozen_string_literal: true

require "spec_helper"

RSpec.describe DepShield::Deprecation do
  it "subscribes to deprecation.rails" do
    expect(DepShield).to(
      receive(:raise_or_capture!)
        .with(name: "deprecation.rails", message: "This has been so deprecated", callstack: ["file1.rb", "file2.rb"])
    )
    
    ActiveSupport::Notifications.instrument(
      "deprecation.rails",
      message: "This has been so deprecated",
      callstack: ["file1.rb", "file2.rb"]
      )
  end
end
