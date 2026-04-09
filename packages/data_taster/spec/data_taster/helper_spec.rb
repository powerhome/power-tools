# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Helper do
  subject(:helper) { Object.new.extend(described_class) }

  describe "#sanitize_command" do
    around do |example|
      ENV["DEV_DUMP_USER"] = "dump_user"
      ENV["DEV_DUMP_PASSWORD"] = "dump_secret"
      example.run
    end

    it "redacts username and password from the command string" do
      cmd = "mysqldump -u #{ENV.fetch('DEV_DUMP_USER')} -p#{ENV.fetch('DEV_DUMP_PASSWORD')} db"
      expect(helper.sanitize_command(cmd)).to eq("mysqldump -u <username> -p<pwd> db")
    end

    it "redacts an extra password from params when given" do
      cmd = "mysql -pother_secret"
      expect(helper.sanitize_command(cmd, { "password" => "other_secret" })).to include("<pwd>")
      expect(helper.sanitize_command(cmd, { "password" => "other_secret" })).not_to include("other_secret")
    end
  end

  describe "#db_config" do
    it "returns the primary ActiveRecord configuration hash for the current env" do
      hash = helper.db_config
      expect(hash).to be_a(Hash)
      expect(hash[:database]).to eq("test_source")
    end
  end

  describe "#logg" do
    it "delegates to DataTaster.logger at debug level" do
      logger = instance_double(Logger, debug: nil)
      allow(DataTaster).to receive(:logger).and_return(logger)

      expect(logger).to receive(:debug).and_yield
      helper.logg("test message")
    end
  end
end
