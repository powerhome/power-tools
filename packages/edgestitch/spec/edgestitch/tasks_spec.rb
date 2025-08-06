# frozen_string_literal: true

require "rails_helper"

RAILS_62_ABOVE = Rails.version >= "6.2"

RSpec.describe Edgestitch::Tasks do
  def rake_execute(task, ...)
    Rake::Task[task].execute(...)
  end

  def dry_run(task, ...) # rubocop:disable Metrics/AbcSize
    output = StringIO.new
    dryrun = Rake.application.options.dryrun
    trace_output = Rake.application.options.trace_output
    Rake.application.options.dryrun = true
    Rake.application.options.trace_output = output
    Rake::Task[task].invoke(...)
    output.string
  ensure
    Rake.application.options.trace_output = trace_output
    Rake.application.options.dryrun = dryrun
  end

  describe ":create" do
    before(:all) { Rails.application.load_tasks }
    before { Rake::Task["db:stitch"].reenable }

    it "defines the create task to create a structure.sql" do
      expect(Rake::Task).to be_task_defined("db:stitch")
    end

    it "renders the structure.sql with all loaded engines" do
      expect(Edgestitch::Stitcher).to(
        receive(:to_file) do |file, *engines|
          expect(file).to eq Rails.root.join("db", "structure.sql").to_s
          expect(engines).to include(Marketing::Engine, Payroll::Engine, Sales::Engine, Rails.application)
        end
      )

      rake_execute "db:stitch"
    end

    it "does not save the structure.sql when the file exists" do
      structure_sql_file = Rails.root.join("db", "structure.sql").to_s

      allow(File).to receive(:exist?).with(structure_sql_file).and_return(true)

      expect(Edgestitch::Stitcher).to(
        receive(:to_file) do |file, *engines|
          expect(file).to eq structure_sql_file
          expect(File).not_to receive(:write)
        end
      )

      rake_execute "db:stitch"
    end

    describe "rails enhancing" do
      it "creates the structure.sql before loading a schema" do
        execution = dry_run("db:schema:load")

        expect(execution).to include <<~OUTPUT
          ** Execute (dry run) db:stitch
          ** Execute (dry run) db:schema:load
        OUTPUT
      end

      it "creates the structure.sql before loading a structure", unless: RAILS_62_ABOVE do
        execution = dry_run("db:structure:load")

        expect(execution).to include <<~OUTPUT
          ** Execute (dry run) db:stitch
          ** Execute (dry run) db:structure:load
        OUTPUT
      end
    end
  end

  describe ":self" do
    before(:all) { Edgestitch::Tasks.define_engine(Sales::Engine, namespace: "db:spec") }
    before { Rake::Task["db:spec:sales"].reenable }

    it "defines the create task to create a structure-self.sql" do
      expect(Rake::Task).to be_task_defined("db:spec:sales")
    end

    it "renders the structure-self.sql with engine tables and migrations" do
      expect(Edgestitch::Exporter).to(
        receive(:export).with(
          Sales::Engine,
          an_instance_of(Edgestitch::Mysql::Dump)
        )
      )

      rake_execute "db:spec:sales"
    end

    describe "rails enhancements" do
      it "creates the structure-self.sql when structure dump is called", unless: RAILS_62_ABOVE do
        execution = dry_run("db:structure:dump")

        expect(execution).to include <<~OUTPUT
          ** Execute (dry run) db:spec:sales
          ** Execute (dry run) db:structure:dump
        OUTPUT
      end

      it "creates the structure-self.sql when schema dump is called" do
        execution = dry_run("db:schema:dump")

        expect(execution).to include <<~OUTPUT
          ** Execute (dry run) db:spec:sales
          ** Execute (dry run) db:schema:dump
        OUTPUT
      end
    end
  end
end
