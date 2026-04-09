# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster do
  it "has a version number" do
    expect(DataTaster::VERSION).not_to be nil
  end

  describe ".logger=" do
    after do
      DataTaster.instance_variable_set(:@logger, nil)
    end

    it "assigns the logger used by .logger" do
      custom = Logger.new(StringIO.new)
      described_class.logger = custom
      expect(described_class.logger).to be(custom)
    end
  end

  describe ".config" do
    after do
      DataTaster.instance_variable_set(:@config, nil)
    end

    it "requires source_client" do
      expect do
        described_class.config(working_client: double("client"), list: [])
      end.to raise_error(ArgumentError, /source_client/)
    end

    it "requires working_client" do
      expect do
        described_class.config(source_client: double("client"), list: [])
      end.to raise_error(ArgumentError, /working_client/)
    end
  end

  describe ".safe_execute" do
    after do
      DataTaster.instance_variable_set(:@config, nil)
    end

    it "disables foreign key checks for the query and restores the previous setting" do
      client = instance_double(Mysql2::Client)
      allow(client).to receive(:query).with("SELECT @@FOREIGN_KEY_CHECKS")
                                      .and_return([{ "@@FOREIGN_KEY_CHECKS" => 1 }])
      allow(client).to receive(:query).with("SET FOREIGN_KEY_CHECKS=0")
      allow(client).to receive(:query).with("UPDATE sample SET x = 1")
      allow(client).to receive(:query).with("SET FOREIGN_KEY_CHECKS=1;")
      allow(client).to receive(:affected_rows).and_return(4)

      described_class.config(
        source_client: client,
        working_client: client,
        list: []
      )

      expect(described_class.safe_execute("UPDATE sample SET x = 1", client)).to eq(4)
    end
  end

  describe ".sample_selected_tables!" do
    after do
      DataTaster.instance_variable_set(:@config, nil)
      DataTaster.instance_variable_set(:@confection, nil)
    end

    it "logs via Rails.logger and samples each selected table" do
      described_class.config(
        source_client: source_db_client,
        working_client: dump_db_client,
        list: []
      )

      sample = instance_double(DataTaster::Sample, serve!: nil)
      allow(described_class).to receive(:selected_tables_names).and_return(["projects"])
      allow(DataTaster::Sample).to receive(:new).with("projects").and_return(sample)
      allow(described_class.logger).to receive(:info)
      rails_logger = instance_double(Logger, info: nil)
      allow(Rails).to receive(:logger).and_return(rails_logger)

      expect(rails_logger).to receive(:info).with("DataTaster: sampling table: projects")
      expect(sample).to receive(:serve!)

      described_class.sample_selected_tables!
    end
  end

  describe ".sanitize_selected_tables!" do
    after do
      DataTaster.instance_variable_set(:@config, nil)
      DataTaster.instance_variable_set(:@confection, nil)
    end

    it "runs the sanitizer when the collection is non-empty and mirrors log lines to Rails.logger" do
      described_class.config(
        source_client: source_db_client,
        working_client: dump_db_client,
        list: []
      )

      collection_payload = { select: "SELECT 1", sanitize: {} }
      users_collection = instance_double(DataTaster::Collection, assemble: collection_payload)
      allow(described_class).to receive(:selected_tables_names).and_return(["users"])
      allow(DataTaster::Collection).to receive(:new).with("users").and_return(users_collection)
      sanitizer = instance_double(DataTaster::Sanitizer, clean!: nil)
      allow(DataTaster::Sanitizer).to receive(:new).with("users", {}).and_return(sanitizer)
      allow(described_class.logger).to receive(:info)
      rails_logger = instance_double(Logger, info: nil)
      allow(Rails).to receive(:logger).and_return(rails_logger)

      expect(rails_logger).to receive(:info).with("DataTaster: sanitizing table: users")
      expect(sanitizer).to receive(:clean!)

      described_class.sanitize_selected_tables!
    end

    it "skips the sanitizer when the assembled collection is empty" do
      described_class.config(
        source_client: source_db_client,
        working_client: dump_db_client,
        list: []
      )

      gone_collection = instance_double(DataTaster::Collection, assemble: {})
      allow(described_class).to receive(:selected_tables_names).and_return(["gone"])
      allow(DataTaster::Collection).to receive(:new).with("gone").and_return(gone_collection)
      allow(described_class.logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(instance_double(Logger, info: nil))

      expect(DataTaster::Sanitizer).not_to receive(:new)

      described_class.sanitize_selected_tables!
    end
  end
end
