# frozen_string_literal: true

require "spec_helper"
require "base64"

RSpec.describe DWConduit::Adapters::TrinoRepository do
  let(:server) { "https://trino.example.com:8443" }
  let(:user) { "app-user" }
  let(:password) { "password123" }
  let(:catalog) { "power_catalog" }
  let(:schema) { "test_schema" }
  let(:table_name) { "test_table" }
  let(:conditions) { "status = 'active'" }

  let(:config) do
    {
      server:,
      user:,
      password:,
      catalog:,
      schema:,
    }
  end

  subject(:repository) { described_class.new(table_name, conditions, config) }

  describe "#initialize" do
    it "sets the correct attributes" do
      expect(repository.server).to eq(server)
      expect(repository.user).to eq(user)
      expect(repository.password).to eq(password)
      expect(repository.catalog).to eq(catalog)
      expect(repository.schema).to eq(schema)
      expect(repository.table_name).to eq(table_name)
      expect(repository.conditions).to eq(conditions)
    end

    context "with environment variables" do
      before do
        allow(ENV).to receive(:fetch).with("TRINO_SERVER", anything).and_return("https://env-trino.example.com")
        allow(ENV).to receive(:fetch).with("TRINO_USER", anything).and_return("env-user")
        allow(ENV).to receive(:fetch).with("TRINO_CATALOG", anything).and_return("env-catalog")
        allow(ENV).to receive(:fetch).with("TRINO_SCHEMA", anything).and_return("env-schema")
        allow(ENV).to receive(:fetch).with("TRINO_PASSWORD", nil).and_return("env-password")
      end

      let(:empty_config) { {} }
      let(:env_repository) { described_class.new(table_name, conditions, empty_config) }

      it "uses environment variables for defaults" do
        expect(env_repository.server).to eq("https://env-trino.example.com")
        expect(env_repository.user).to eq("env-user")
        expect(env_repository.password).to eq("env-password")
        expect(env_repository.catalog).to eq("env-catalog")
        expect(env_repository.schema).to eq("env-schema")
      end
    end

    context "with missing required configuration" do
      let(:config) { { server: "", user: nil } }

      it "raises an argument error" do
        expect { repository }.to raise_error(ArgumentError, /cannot be nil or empty/)
      end
    end
  end

  describe "#query" do
    let(:query_url) { "#{server}/v1/statement" }
    let(:next_url) { "#{server}/v1/statement/20240101_1" }

    let(:auth_header) { "Basic #{Base64.strict_encode64("#{user}:#{password}")}" }

    let(:initial_response) do
      {
        "id" => "20240101_1",
        "infoUri" => "#{server}/ui/query.html?20240101_1",
        "nextUri" => next_url,
        "columns" => [
          { "name" => "id", "type" => "integer" },
          { "name" => "name", "type" => "varchar" },
        ],
        "data" => [
          [1, "Product A"],
        ],
      }
    end

    let(:final_response) do
      {
        "id" => "20240101_1",
        "infoUri" => "#{server}/ui/query.html?20240101_1",
        "columns" => [
          { "name" => "id", "type" => "integer" },
          { "name" => "name", "type" => "varchar" },
        ],
        "data" => [
          [2, "Product B"],
        ],
      }
    end

    before do
      stub_request(:post, query_url)
        .with(
          body: "SELECT * FROM #{table_name} WHERE #{conditions}",
          headers: {
            "Authorization" => auth_header,
            "X-Trino-Catalog" => catalog,
            "X-Trino-Schema" => schema,
          }
        )
        .to_return(status: 200, body: initial_response.to_json)

      stub_request(:get, next_url)
        .with(
          headers: {
            "Authorization" => auth_header,
            "X-Trino-Catalog" => catalog,
            "X-Trino-Schema" => schema,
          }
        )
        .to_return(status: 200, body: final_response.to_json)
    end

    it "executes the query with correct headers" do
      repository.query

      expect(WebMock).to have_requested(:post, query_url)
        .with(
          body: "SELECT * FROM #{table_name} WHERE #{conditions}",
          headers: {
            "Authorization" => auth_header,
            "X-Trino-Catalog" => catalog,
            "X-Trino-Schema" => schema,
          }
        )
    end

    it "follows pagination and combines results" do
      result = repository.query

      expect(result).to eq([
                             { "id" => 1, "name" => "Product A" },
                             { "id" => 2, "name" => "Product B" },
                           ])

      expect(WebMock).to have_requested(:get, next_url)
    end

    context "with a custom query" do
      let(:custom_query) { "SELECT count(*) as count FROM test_table" }

      before do
        stub_request(:post, query_url)
          .with(
            body: custom_query,
            headers: {
              "Authorization" => auth_header,
              "X-Trino-Catalog" => catalog,
              "X-Trino-Schema" => schema,
            }
          )
          .to_return(status: 200, body: {
            "columns" => [{ "name" => "count", "type" => "bigint" }],
            "data" => [[42]],
          }.to_json)
      end

      it "executes the provided custom query" do
        result = repository.query(custom_query)

        expect(result).to eq([{ "count" => 42 }])

        expect(WebMock).to have_requested(:post, query_url)
          .with(body: custom_query)
      end
    end

    context "when the query fails" do
      before do
        stub_request(:post, query_url)
          .to_return(
            status: 400,
            body: { "error" => { "message" => "SQL syntax error" } }.to_json
          )
      end

      it "raises an error with the error message" do
        expect { repository.query }.to raise_error(DWConduit::Error, /Query failed/)
      end
    end
  end

  describe "#execute" do
    let(:query_url) { "#{server}/v1/statement" }
    let(:sql_query) { "SELECT id, name FROM test_table WHERE id = 1" }

    let(:response) do
      {
        "columns" => [
          { "name" => "id", "type" => "integer" },
          { "name" => "name", "type" => "varchar" },
        ],
        "data" => [
          [1, "Test Product"],
        ],
      }
    end

    before do
      stub_request(:post, query_url)
        .with(body: sql_query)
        .to_return(status: 200, body: response.to_json)
    end

    it "executes the provided SQL query" do
      result = repository.execute(sql_query)

      expect(result).to eq([{ "id" => 1, "name" => "Test Product" }])

      expect(WebMock).to have_requested(:post, query_url)
        .with(body: sql_query)
    end

    context "when the query fails" do
      before do
        stub_request(:post, query_url)
          .with(body: sql_query)
          .to_return(
            status: 400,
            body: { "error" => { "message" => "SQL syntax error" } }.to_json
          )
      end

      it "raises an error with the error message" do
        expect { repository.execute(sql_query) }.to raise_error(DWConduit::Error, /Query failed/)
      end
    end
  end
end
