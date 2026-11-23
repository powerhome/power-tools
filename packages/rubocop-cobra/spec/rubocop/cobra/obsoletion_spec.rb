# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rubocop-cobra obsoletions" do
  before { RuboCop::Cobra::Plugin.new.rules(nil) }

  it "explains that Cobra/HelperFilePlacement was removed in favor of Style/NoHelpers" do
    config = RuboCop::Config.new({ "Cobra/HelperFilePlacement" => { "Enabled" => true } }, ".rubocop.yml")

    expect { RuboCop::ConfigObsoletion.new(config).reject_obsolete! }
      .to raise_error(RuboCop::ValidationError, %r{Cobra/HelperFilePlacement.*removed.*Style/NoHelpers}m)
  end
end
