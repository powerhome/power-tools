# frozen_string_literal: true

require "spec_helper"

# Model defined at file scope so AR is satisfied with a named class.
class InjectionTarget < ActiveRecord::Base
  self.table_name = "users"
end

RSpec.describe "SQL injection prevention through the AR pipeline" do
  include TrinoFake

  let(:statement_url) { "#{TrinoFake::BASE_URL}/v1/statement" }

  before do
    ActiveRecord::Base.establish_connection(trino_config)

    stub_trino_query(
      sql: /information_schema\.columns/,
      columns: [%w[column_name varchar], %w[data_type varchar], %w[is_nullable varchar]],
      rows: [
        %w[id bigint NO],
        %w[name varchar YES],
        ["age", "integer", "YES"],
        ["balance", "decimal(10, 2)", "YES"],
        ["active", "boolean", "YES"],
        %w[birthdate date YES],
      ],
      query_id: "schema"
    )

    stub_trino_query(
      sql: "SHOW TABLES",
      columns: [%w[Table varchar]],
      rows: [["users"]],
      query_id: "show_tables"
    )

    stub_trino_query(
      sql: /SELECT.+FROM "users"/i,
      columns: [%w[id bigint]],
      rows: [],
      query_id: "select"
    )

    InjectionTarget.reset_column_information
  end

  after do
    ActiveRecord::Base.connection_handler.clear_all_connections!(:all)
  end

  def expect_sent_sql(matcher)
    expect(WebMock).to have_requested(:post, statement_url).with(body: matcher)
  end

  describe "classic injection payloads in where(column: value)" do
    {
      "drop-table attempt" => ["'; DROP TABLE users; --", /'''; DROP TABLE users; --'/],
      "Little Bobby Tables" => ["Robert'); DROP TABLE students; --", /'Robert''\); DROP TABLE students; --'/],
      "tautology attack" => ["' OR '1'='1",                        /''' OR ''1''=''1'/],
      "plain apostrophe" => ["O'Brien",                            /'O''Brien'/],
      "embedded line comment" => ["value -- comment", /'value -- comment'/],
      "embedded block comment" => ["value/*x*/end", %r{'value/\*x\*/end'}],
      "unicode (multi-byte)" => ["Café", /'Café'/],
      "single quote alone" => ["'", /''''/], # 4 quotes: open, ''-escaped quote, close
      "empty string" => ["", /"name" = ''/],
    }.each do |label, (payload, matcher)|
      it "safely escapes the #{label} payload" do
        InjectionTarget.where(name: payload).to_a
        expect_sent_sql(matcher)
      end
    end
  end

  describe "non-string types render as native SQL literals" do
    it "renders integers without quoting" do
      InjectionTarget.where(age: 42).to_a
      expect_sent_sql(/"age" = 42(?!\d)/)
    end

    it "renders booleans without quoting" do
      InjectionTarget.where(active: true).to_a
      expect_sent_sql(/"active" = (TRUE|true)/i)
    end

    it "renders dates as Trino DATE literals" do
      InjectionTarget.where(birthdate: Date.new(2024, 1, 31)).to_a
      expect_sent_sql(/"birthdate" = (DATE )?'2024-01-31'/)
    end

    it "renders BigDecimal as a bare numeric (not a string)" do
      InjectionTarget.where(balance: BigDecimal("100.50")).to_a
      expect_sent_sql(/"balance" = 100\.50?(?!\d)/)
    end

    it "renders nil via IS NULL rather than as a string" do
      InjectionTarget.where(name: nil).to_a
      expect_sent_sql(/"name" IS NULL/)
      # Defense in depth: ensure nil never becomes the literal string 'NULL'.
      expect(WebMock).not_to have_requested(:post, statement_url).with(body: /"name" = 'NULL'/)
    end
  end

  describe "compound conditions" do
    it "escapes every element of an array IN clause" do
      InjectionTarget.where(name: ["Alice", "O'Brien", "' OR 1=1; --"]).to_a
      expect_sent_sql(/IN \('Alice', 'O''Brien', ''' OR 1=1; --'\)/)
    end

    it "renders inclusive ranges as BETWEEN with both bounds quoted" do
      InjectionTarget.where(age: 18..65).to_a
      expect_sent_sql(/"age" BETWEEN 18 AND 65/)
    end
  end

  describe "AR's positional and named arg substitution" do
    it "escapes positional args (the ? form)" do
      InjectionTarget.where("name = ?", "'; DROP TABLE users; --").to_a
      expect_sent_sql(/'''; DROP TABLE users; --'/)
    end

    it "escapes named args (the :name form)" do
      InjectionTarget.where("name = :n", n: "O'Brien").to_a
      expect_sent_sql(/'O''Brien'/)
    end

    it "escapes positional args inside compound conditions" do
      InjectionTarget.where("name = ? OR name = ?", "O'Brien", "' OR 1=1; --").to_a
      expect_sent_sql(/'O''Brien'/)
      expect_sent_sql(/''' OR 1=1; --'/)
    end
  end

  describe "identifier quoting" do
    it "always wraps table names in double quotes" do
      InjectionTarget.where(name: "anything").to_a
      expect_sent_sql(/FROM "users"/)
    end

    it "always wraps column names in double quotes" do
      InjectionTarget.where(name: "anything").to_a
      expect_sent_sql(/"name" =/)
    end
  end
end
