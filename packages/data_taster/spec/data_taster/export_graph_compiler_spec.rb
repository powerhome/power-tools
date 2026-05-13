# frozen_string_literal: true

require "spec_helper"

# Lightweight ActiveRecord graph — no DB connection (explicit primary keys).
module ExportGraphCompilerSpec
  module Dealer
    class Dealer < ActiveRecord::Base
      self.table_name = "dealer_dealers"
      self.primary_key = "id"
    end
  end

  module CreditApplication
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end

    class LoanApplicationStatus < ApplicationRecord
      self.table_name = "credit_application_loan_application_statuses"
      self.primary_key = "id"
    end

    class LoanApplicationApplicant < ApplicationRecord
      self.table_name = "credit_application_loan_application_applicants"
      self.primary_key = "id"
      belongs_to :loan_application, class_name: "ExportGraphCompilerSpec::CreditApplication::LoanApplication"
      belongs_to :applicant, class_name: "ExportGraphCompilerSpec::CreditApplication::Applicant"
    end

    class Applicant < ApplicationRecord
      self.table_name = "credit_application_applicants"
      self.primary_key = "id"
    end

    class LoanApplicationOffer < ApplicationRecord
      self.table_name = "credit_application_loan_application_offers"
      self.primary_key = "id"
    end

    class ActivityFeedItem < ApplicationRecord
      self.table_name = "credit_application_activity_feed_items"
      self.primary_key = "id"
    end

    class LoanApplication < ApplicationRecord
      self.table_name = "credit_application_loan_applications"
      self.primary_key = "id"
      belongs_to :dealer, class_name: "ExportGraphCompilerSpec::Dealer::Dealer"
      has_one :status, class_name: "ExportGraphCompilerSpec::CreditApplication::LoanApplicationStatus"
      has_many :loan_application_applicants, class_name: "ExportGraphCompilerSpec::CreditApplication::LoanApplicationApplicant"
      has_many :applicants, through: :loan_application_applicants
      has_many :offers, class_name: "ExportGraphCompilerSpec::CreditApplication::LoanApplicationOffer"
      has_many :activity_feed_items, class_name: "ExportGraphCompilerSpec::CreditApplication::ActivityFeedItem",
                                     as: :context
    end
  end
end

RSpec.describe DataTaster::ExportGraphCompiler do
  let(:graph_anchor_allowlist) { nil }
  let(:source_client) { instance_double(Mysql2::Client, query_options: { database: "spec_source_db" }) }
  let(:stub_config) do
    DataTaster::Config.new(
      months: nil,
      list: [],
      source_client: source_client,
      working_client: nil,
      include_insert: false,
      filename: nil,
      graph_anchor_allowlist: graph_anchor_allowlist
    )
  end

  before { allow(DataTaster).to receive(:config).and_return(stub_config) }

  describe ".merge_into!" do
    let(:graph) do
      {
        "anchor" => {
          "model" => "ExportGraphCompilerSpec::CreditApplication::LoanApplication",
          "where_sql" => "created_at >= '2000-01-01'",
          "order" => "id DESC",
          "limit" => 10,
        },
        "includes" => %w[status loan_application_applicants applicants offers],
      }
    end

    it "expands graphs into table clauses, including the anchor table, and drops the reserved key" do
      hash = {
        "data_taster_export_graphs" => { "g" => graph },
        "other_table" => "1 = 1",
      }
      described_class.merge_into!(hash)

      expect(hash).not_to have_key("data_taster_export_graphs")
      expect(hash["credit_application_loan_applications"])
        .to include("`id` IN (", "LIMIT 10", "spec_source_db")
      expect(hash["credit_application_loan_application_statuses"]).to include("loan_application_id")
      expect(hash["credit_application_loan_application_applicants"]).to include("loan_application_id")
      expect(hash["credit_application_applicants"]).to include("credit_application_loan_application_applicants")
      expect(hash["credit_application_loan_application_offers"]).to include("loan_application_id")
      expect(hash["other_table"]).to eq("1 = 1")
    end

    it "lets explicit table keys override compiled fragments" do
      hash = {
        "data_taster_export_graphs" => { "g" => graph },
        "credit_application_loan_application_statuses" => "1 = 0",
      }
      described_class.merge_into!(hash)

      expect(hash["credit_application_loan_application_statuses"]).to eq("1 = 0")
    end

    it "raises on unknown associations" do
      bad = graph.merge("includes" => %w[not_a_real_assoc])
      hash = { "data_taster_export_graphs" => { "g" => bad } }
      expect { described_class.merge_into!(hash) }.to raise_error(
        DataTaster::ExportGraphCompiler::Error,
        /Unknown association/
      )
    end

    context "with graph_anchor_allowlist" do
      let(:graph_anchor_allowlist) { ["ExportGraphCompilerSpec::"] }

      it "raises when the anchor model is outside the allowlist" do
        bad_anchor = graph.merge(
          "anchor" => graph["anchor"].merge("model" => "Array")
        )
        hash = { "data_taster_export_graphs" => { "g" => bad_anchor } }
        expect { described_class.merge_into!(hash) }.to raise_error(
          DataTaster::ExportGraphCompiler::Error,
          /not allowed/
        )
      end
    end

    it "skips polymorphic-inverse includes without failing" do
      poly_graph = graph.merge("includes" => %w[activity_feed_items])
      hash = { "data_taster_export_graphs" => { "g" => poly_graph } }
      allow(DataTaster.logger).to receive(:info)
      described_class.merge_into!(hash)

      expect(hash).not_to have_key("credit_application_activity_feed_items")
    end

    it "emits belongs_to parent constraints" do
      dealer_graph = graph.merge("includes" => %w[dealer])
      hash = { "data_taster_export_graphs" => { "g" => dealer_graph } }
      described_class.merge_into!(hash)

      expect(hash["dealer_dealers"]).to include("dealer_id").and include("credit_application_loan_applications")
    end
  end
end
