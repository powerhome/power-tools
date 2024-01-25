# frozen_string_literal: true

require "spec_helper"

RSpec.describe DepShield::Deprecation do
  context "#raise_or_capture!" do
    describe "configured to capture_deprecation" do
      before do
        allow(NitroConfig).to receive(:get).with("nitro_errors/capture_deprecation").and_return true
      end

      it "allowlisted" do
        expect(Rails.logger).to receive(:warn).with("NITRO DEPRECATION WARNING", any_args)
        expect(Sentry).to_not receive(:capture_exception)

        DepShield::Deprecation.new(
          name: "test_whitelist", message: "I'm allowlisted!", callstack: ["spec/nitro_errors/deprecation_spec.rb"]
        ).raise_or_capture!
      end

      it "NOT allowlisted" do
        expect(Rails.logger).to receive(:warn).with("NITRO DEPRECATION WARNING", any_args)
        expect(Sentry).to receive(:capture_exception)

        DepShield::Deprecation.new(
          name: "test", message: "Test!", callstack: ["spec/nitro_errors/deprecation_spec.rb"]
        ).raise_or_capture!
      end
    end

    describe "NOT configured to capture_deprecation" do
      before do
        allow(NitroConfig).to receive(:get).with("nitro_errors/capture_deprecation").and_return false
      end

      it "allowlisted" do
        expect(Rails.logger).to receive(:warn).with("NITRO DEPRECATION WARNING", any_args)
        expect(Sentry).to_not receive(:capture_exception)

        DepShield::Deprecation.new(
          name: "test_whitelist", message: "I'm allowlisted!", callstack: ["spec/nitro_errors/deprecation_spec.rb"]
        ).raise_or_capture!
      end

      it "NOT allowlisted" do
        expect(Rails.logger).to receive(:warn).with("NITRO DEPRECATION WARNING", any_args)

        expect do
          DepShield::Deprecation.new(
            name: "test", message: "Test!", callstack: ["spec/nitro_errors/deprecation_spec.rb"]
          ).raise_or_capture!
        end.to raise_error(DepShield::Error)
      end
    end
  end
end
