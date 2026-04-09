# frozen_string_literal: true

require "spec_helper"

RSpec.describe DataTaster::Sample do
  let(:skippable_yaml) { File.join(__dir__, "..", "fixtures", "skippable_and_deprecated_tables.yml") }
  let(:broken_where_yaml) { File.join(__dir__, "..", "fixtures", "broken_where_clause.yml") }

  def reset_taster!
    DataTaster.instance_variable_set(:@config, nil)
    DataTaster.instance_variable_set(:@confection, nil)
  end

  describe "#serve!" do
    context "when the collection is empty and include_insert is true" do
      before do
        reset_taster!
        DataTaster.config(
          list: [skippable_yaml],
          source_client: source_db_client,
          working_client: dump_db_client,
          include_insert: true
        )
      end

      after { reset_taster! }

      it "drops the working copy of the table" do
        expect(DataTaster).to receive(:safe_execute).with("DROP TABLE IF EXISTS _ignored_by_prefix").and_return(0)

        described_class.new("_ignored_by_prefix").serve!
      end
    end

    context "when the SELECT fails" do
      before do
        reset_taster!
        DataTaster.config(
          list: [broken_where_yaml],
          source_client: source_db_client,
          working_client: dump_db_client,
          include_insert: true
        )
      end

      after { reset_taster! }

      it "re-raises with the table name and SQL in the message" do
        expect do
          described_class.new("users").serve!
        end.to raise_error(/executing SQL statement for users/)
      end
    end
  end
end
