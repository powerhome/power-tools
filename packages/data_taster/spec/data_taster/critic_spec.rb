# frozen_string_literal: true

require "spec_helper"
require "data_taster/critic"

RSpec.describe DataTaster::Critic do
  include DatabaseHelper

  let(:critic) { described_class.new }
  let(:logger) { instance_double(Logger) }

  before do
    allow(DataTaster).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
  end

  describe "#initialize" do
    it "initializes with empty reviews array" do
      expect(critic.reviews).to eq([])
    end
  end

  describe "#criticize_dump" do
    it "measures execution time and logs completion" do
      expect(logger).to receive(:info).with(/Dump completed in \d+\.\d+ seconds/)
      expect(logger).to receive(:info).with("--------------------------------")
      expect(logger).to receive(:info).with("Slowest tables:")
      expect(logger).to receive(:info).with("--------------------------------")
      expect(logger).to receive(:info).with("Largest tables by size:")
      expect(logger).to receive(:info).with("--------------------------------")
      expect(logger).to receive(:info).with("Largest tables by rows:")
      expect(logger).to receive(:info).with("--------------------------------")

      critic.criticize_dump do
        # Simulate some work
        sleep(0.0001)
      end
    end

    it "executes the block and reports exceptional tables" do
      block_executed = false
      critic.criticize_dump { block_executed = true }
      expect(block_executed).to be true
    end

    it "calls report_exceptional_tables after execution" do
      expect(critic).to receive(:report_exceptional_tables)
      critic.criticize_dump { "test" }
    end
  end

  describe "#criticize_sample" do
    let(:table_name) { "users" }
    let(:mock_count_result) { [{ "COUNT(*)" => 150 }] }
    let(:mock_size_result) { [{ "size_mb" => 2.5 }] }

    before do
      allow(DataTaster).to receive(:safe_execute).with("SELECT COUNT(*) FROM #{table_name}").and_return(mock_count_result)
      allow(DataTaster).to receive(:safe_execute).with(include("information_schema.tables")).and_return(mock_size_result)
    end

    it "measures execution time and creates a review" do
      expect(logger).to receive(:info).with("--------------------------------").twice
      expect(logger).to receive(:info).with(/Table #{table_name} completed in \d+\.\d+ seconds, dumped 150 rows and 2.5 MB of data/)

      critic.criticize_sample(table_name) do
        # Simulate some work
        sleep(0.0001)
      end

      expect(critic.reviews.length).to eq(1)

      review = critic.reviews.first
      expect(review[:table_name]).to eq(table_name)
      expect(review[:rows]).to eq(150)
      expect(review[:size]).to eq(2.5)
      expect(review[:time]).to be_a(Float)
    end

    it "calls safe_execute for row count and table size" do
      expect(DataTaster).to receive(:safe_execute).with("SELECT COUNT(*) FROM #{table_name}")
      expect(DataTaster).to receive(:safe_execute).with(include("information_schema.tables"))

      critic.criticize_sample(table_name) { "test" }
    end

    it "logs horizontal rules and publishes review" do
      expect(critic).to receive(:log_horizontal_rule).twice
      expect(critic).to receive(:publish).with(hash_including(table_name: table_name))

      critic.criticize_sample(table_name) { "test" }
    end

    it "handles different table sizes and row counts" do
      large_count_result = [{ "COUNT(*)" => 10000 }]
      large_size_result = [{ "size_mb" => 50.75 }]

      allow(DataTaster).to receive(:safe_execute).with("SELECT COUNT(*) FROM #{table_name}").and_return(large_count_result)
      allow(DataTaster).to receive(:safe_execute).with(include("information_schema.tables")).and_return(large_size_result)

      critic.criticize_sample(table_name) { "test" }

      review = critic.reviews.first
      expect(review[:rows]).to eq(10000)
      expect(review[:size]).to eq(50.75)
    end
  end

  describe "#table_size_sql" do
    it "generates correct SQL for table size query" do
      table_name = "test_table"
      sql = critic.send(:table_size_sql, table_name)

      expect(sql).to include("information_schema.tables")
      expect(sql).to include("table_name = 'test_table'")
      expect(sql).to include("DATA_LENGTH + INDEX_LENGTH")
      expect(sql).to include("size_mb")
    end
  end

  describe "#publish" do
    let(:review) do
      {
        table_name: "users",
        time: 1.2345,
        rows: 100,
        size: 2.5
      }
    end

    it "logs table information with correct formatting" do
      expect(logger).to receive(:info).with("Table users completed in 1.2345 seconds, dumped 100 rows and 2.5 MB of data")

      critic.send(:publish, review)
    end

    it "handles singular row count" do
      singular_review = review.merge(rows: 1)
      expect(logger).to receive(:info).with(/dumped 1 row/)

      critic.send(:publish, singular_review)
    end

    it "handles plural row count" do
      plural_review = review.merge(rows: 2)
      expect(logger).to receive(:info).with(/dumped 2 rows/)

      critic.send(:publish, plural_review)
    end
  end

  describe "#log_horizontal_rule" do
    it "logs horizontal rule" do
      expect(logger).to receive(:info).with("--------------------------------")
      critic.send(:log_horizontal_rule)
    end
  end

  describe "#report_exceptional_tables" do
    before do
      critic.reviews << { table_name: "slow_table", time: 5.0, rows: 100, size: 1.0 }
      critic.reviews << { table_name: "fast_table", time: 0.5, rows: 50, size: 0.5 }
      critic.reviews << { table_name: "large_table", time: 2.0, rows: 1000, size: 10.0 }
      critic.reviews << { table_name: "small_table", time: 1.0, rows: 10, size: 0.1 }
    end

    it "calls all reporting methods" do
      expect(critic).to receive(:log_horizontal_rule)
      expect(critic).to receive(:report_slowest_tables)
      expect(critic).to receive(:report_largest_tables_by_size)
      expect(critic).to receive(:report_largest_tables_by_rows)

      critic.send(:report_exceptional_tables)
    end
  end

  describe "#report_slowest_tables" do
    before(:each) do
      critic.reviews.clear
      critic.reviews << { table_name: "table1", time: 1.0, rows: 100, size: 1.0 }
      critic.reviews << { table_name: "table2", time: 3.0, rows: 200, size: 2.0 }
      critic.reviews << { table_name: "table3", time: 2.0, rows: 150, size: 1.5 }
      critic.reviews << { table_name: "table4", time: 4.0, rows: 300, size: 3.0 }
      critic.reviews << { table_name: "table5", time: 0.5, rows: 50, size: 0.5 }
      critic.reviews << { table_name: "table6", time: 5.0, rows: 400, size: 4.0 }
    end

    it "logs slowest tables header and horizontal rules" do
      expect(logger).to receive(:info).with("Slowest tables:")
      expect(logger).to receive(:info).with("--------------------------------").twice

      critic.send(:report_slowest_tables)
    end

    it "publishes the 5 slowest tables in descending order (largest times first)" do
      # Collect all publish calls to verify order
      published_reviews = []
      allow(critic).to receive(:publish) do |review|
        published_reviews << review
      end

      critic.send(:report_slowest_tables)

      # Verify the order and content (largest times first)
      expect(published_reviews.length).to eq(5)
      expect(published_reviews[0][:table_name]).to eq("table6")
      expect(published_reviews[0][:time]).to eq(5.0)
      expect(published_reviews[1][:table_name]).to eq("table4")
      expect(published_reviews[1][:time]).to eq(4.0)
      expect(published_reviews[2][:table_name]).to eq("table2")
      expect(published_reviews[2][:time]).to eq(3.0)
      expect(published_reviews[3][:table_name]).to eq("table3")
      expect(published_reviews[3][:time]).to eq(2.0)
      expect(published_reviews[4][:table_name]).to eq("table1")
      expect(published_reviews[4][:time]).to eq(1.0)
    end

    it "publishes tables in the correct order" do
      # Alternative approach using RSpec's ordered matcher
      expect(critic).to receive(:publish).with(hash_including(table_name: "table6", time: 5.0)).ordered
      expect(critic).to receive(:publish).with(hash_including(table_name: "table4", time: 4.0)).ordered
      expect(critic).to receive(:publish).with(hash_including(table_name: "table2", time: 3.0)).ordered
      expect(critic).to receive(:publish).with(hash_including(table_name: "table3", time: 2.0)).ordered
      expect(critic).to receive(:publish).with(hash_including(table_name: "table1", time: 1.0)).ordered

      critic.send(:report_slowest_tables)
    end
  end

  describe "#report_largest_tables_by_size" do
    before(:each) do
      critic.reviews.clear
      critic.reviews << { table_name: "table1", time: 1.0, rows: 100, size: 1.0 }
      critic.reviews << { table_name: "table2", time: 2.0, rows: 200, size: 5.0 }
      critic.reviews << { table_name: "table3", time: 3.0, rows: 150, size: 2.0 }
      critic.reviews << { table_name: "table4", time: 4.0, rows: 300, size: 8.0 }
      critic.reviews << { table_name: "table5", time: 5.0, rows: 50, size: 0.5 }
      critic.reviews << { table_name: "table6", time: 6.0, rows: 400, size: 10.0 }
    end

    it "logs largest tables by size header and horizontal rules" do
      expect(logger).to receive(:info).with("Largest tables by size:")
      expect(logger).to receive(:info).with("--------------------------------").twice

      critic.send(:report_largest_tables_by_size)
    end

    it "publishes the 5 largest tables by size in descending order (largest first)" do
      # Collect all publish calls to verify order
      published_reviews = []
      allow(critic).to receive(:publish) do |review|
        published_reviews << review
      end

      critic.send(:report_largest_tables_by_size)

      # Verify the order and content (largest sizes first)
      expect(published_reviews.length).to eq(5)
      expect(published_reviews[0][:table_name]).to eq("table6")
      expect(published_reviews[0][:size]).to eq(10.0)
      expect(published_reviews[1][:table_name]).to eq("table4")
      expect(published_reviews[1][:size]).to eq(8.0)
      expect(published_reviews[2][:table_name]).to eq("table2")
      expect(published_reviews[2][:size]).to eq(5.0)
      expect(published_reviews[3][:table_name]).to eq("table3")
      expect(published_reviews[3][:size]).to eq(2.0)
      expect(published_reviews[4][:table_name]).to eq("table1")
      expect(published_reviews[4][:size]).to eq(1.0)
    end
  end

  describe "#report_largest_tables_by_rows" do
    before(:each) do
      critic.reviews.clear
      critic.reviews << { table_name: "table1", time: 1.0, rows: 100, size: 1.0 }
      critic.reviews << { table_name: "table2", time: 2.0, rows: 500, size: 2.0 }
      critic.reviews << { table_name: "table3", time: 3.0, rows: 200, size: 1.5 }
      critic.reviews << { table_name: "table4", time: 4.0, rows: 800, size: 3.0 }
      critic.reviews << { table_name: "table5", time: 5.0, rows: 50, size: 0.5 }
      critic.reviews << { table_name: "table6", time: 6.0, rows: 1000, size: 4.0 }
    end

    it "logs largest tables by rows header and horizontal rules" do
      expect(logger).to receive(:info).with("Largest tables by rows:")
      expect(logger).to receive(:info).with("--------------------------------").twice

      critic.send(:report_largest_tables_by_rows)
    end

    it "publishes the 5 largest tables by rows in descending order (largest first)" do
      # Collect all publish calls to verify order
      published_reviews = []
      allow(critic).to receive(:publish) do |review|
        published_reviews << review
      end

      critic.send(:report_largest_tables_by_rows)

      # Verify the order and content (largest row counts first)
      expect(published_reviews.length).to eq(5)
      expect(published_reviews[0][:table_name]).to eq("table6")
      expect(published_reviews[0][:rows]).to eq(1000)
      expect(published_reviews[1][:table_name]).to eq("table4")
      expect(published_reviews[1][:rows]).to eq(800)
      expect(published_reviews[2][:table_name]).to eq("table2")
      expect(published_reviews[2][:rows]).to eq(500)
      expect(published_reviews[3][:table_name]).to eq("table3")
      expect(published_reviews[3][:rows]).to eq(200)
      expect(published_reviews[4][:table_name]).to eq("table1")
      expect(published_reviews[4][:rows]).to eq(100)
    end
  end

  describe "#log_info" do
    it "delegates to DataTaster.logger.info" do
      message = "test message"
      expect(DataTaster.logger).to receive(:info).with(message)
      critic.send(:log_info, message)
    end
  end

  describe "integration with DataTaster.safe_execute" do
    let(:table_name) { "test_table" }

    before do
      allow(DataTaster).to receive(:safe_execute).and_call_original
    end

    it "handles database errors gracefully in criticize_sample" do
      allow(DataTaster).to receive(:safe_execute).and_raise(StandardError.new("Database error"))

      expect { critic.criticize_sample(table_name) { "test" } }.to raise_error(StandardError, "Database error")
    end

    it "handles empty result sets" do
      allow(DataTaster).to receive(:safe_execute).and_return([])

      expect { critic.criticize_sample(table_name) { "test" } }.to raise_error(NoMethodError)
    end
  end

  describe "edge cases" do
    it "handles empty reviews array in reporting methods" do
      critic.reviews.clear

      expect(logger).to receive(:info).with("Slowest tables:")
      expect(logger).to receive(:info).with("--------------------------------").twice

      expect { critic.send(:report_slowest_tables) }.not_to raise_error
    end

    it "handles reviews with nil values" do
      critic.reviews << { table_name: "table1", time: nil, rows: nil, size: nil }

      expect { critic.send(:report_slowest_tables) }.not_to raise_error
    end

    it "handles very large numbers in reviews" do
      large_review = {
        table_name: "huge_table",
        time: 999999.9999,
        rows: 999999999,
        size: 999999.99
      }

      expect(logger).to receive(:info).with(/Table huge_table completed in 999999\.9999 seconds, dumped 999999999 rows and 999999\.99 MB of data/)

      critic.send(:publish, large_review)
    end
  end
end
