# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::Trino::ReadOnly do
  let(:host) do
    Class.new do
      include ActiveRecord::ConnectionAdapters::Trino::ReadOnly
    end.new
  end

  ActiveRecord::ConnectionAdapters::Trino::ReadOnly::WRITE_METHODS.each do |method|
    it "raises ReadOnlyError for ##{method}" do
      expect { host.public_send(method) }
        .to raise_error(Stagecoach::ReadOnlyError, /#{method}/)
    end
  end

  it "includes a hint that stagecoach is read-only in the error message" do
    expect { host.insert }
      .to raise_error(Stagecoach::ReadOnlyError, /read-only/)
  end
end
