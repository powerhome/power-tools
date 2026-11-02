# frozen_string_literal: true

require "spec_helper"
require "open3"

# What an application coming from activerecord-mysql2rgeo-adapter keeps, and
# the differences that come from not being a separate adapter. Each
# difference is listed in the README's migration guide.
RSpec.describe "Migrating from activerecord-mysql2rgeo-adapter" do
  # Returns the script's standard output, standard error and status.
  def run_ruby(script)
    Open3.capture3(RbConfig.ruby, "-Ilib", "-rbundler/setup", "-e", script)
  end

  it "has no mysql2rgeo adapter: database.yml names trilogy or mysql2" do
    expect { ActiveRecord::ConnectionAdapters.resolve("mysql2rgeo") }.to raise_error(ActiveRecord::AdapterNotFound)
  end

  it "reports the driver's adapter name" do
    expect(ActiveRecord::Base.with_connection(&:adapter_name)).to eq(TestDatabase.adapter.capitalize)
  end

  describe "column.spatial?" do
    before do
      ActiveRecord::Base.with_connection do |connection|
        connection.create_table(:places, force: true) do |t|
          t.string :name
          t.st_point :location, srid: 3857
        end
      end
    end

    after do
      ActiveRecord::Base.with_connection { |connection| connection.drop_table(:places, if_exists: true) }
    end

    it "answers for every column, as upstream columns did" do
      columns = ActiveRecord::Base.with_connection { |connection| connection.columns(:places) }

      expect(columns.to_h { |column| [column.name, column.spatial?] })
        .to eq("id" => false, "name" => false, "location" => true)
    end
  end

  describe "deprecated constants" do
    let(:deprecations) { [] }
    let(:deprecator) { ActiveRecord::MysqlRgeo.deprecator }

    before do
      @behavior = deprecator.behavior
      deprecator.behavior = ->(message, *) { deprecations << message }
    end

    after do
      deprecator.behavior = @behavior
    end

    %w[ActiveRecord::Type::Spatial ActiveRecord::ConnectionAdapters::Mysql2Rgeo::OID::Spatial].each do |name|
      it "keeps #{name} as a deprecated name of the spatial type" do
        type = Object.const_get(name).new("geometry(Point,3857)")

        expect(type).to be_a(ActiveRecord::MysqlRgeo::Type::Spatial)
        expect(type.cast("POINT(1 2)")).to have_attributes(srid: 3857)
        expect(deprecations).to contain_exactly(/#{Regexp.escape(name)} is deprecated.*ActiveRecord::MysqlRgeo::Type::Spatial/)
      end
    end
  end

  describe "loading both gems" do
    # Stands in for activerecord-mysql2rgeo-adapter, which defines this class.
    upstream_gem = <<~RUBY
      require "active_record"
      ActiveRecord::ConnectionAdapters::Mysql2RgeoAdapter = Class.new
    RUBY

    it "raises when activerecord-mysql2rgeo-adapter was loaded first" do
      _, errors, status = run_ruby(%(#{upstream_gem}require "activerecord-mysql-rgeo"\nActiveRecord::Base))

      expect(status).not_to be_success
      expect(errors).to include("Remove activerecord-mysql2rgeo-adapter from your Gemfile")
    end

    it "raises when activerecord-mysql2rgeo-adapter is loaded after this gem" do
      _, errors, status = run_ruby(%(require "activerecord-mysql-rgeo"\n#{upstream_gem}ActiveRecord::Base))

      expect(status).not_to be_success
      expect(errors).to include("Remove activerecord-mysql2rgeo-adapter from your Gemfile")
    end
  end

  it "registers its deprecator with the Rails application" do
    output, errors, status = run_ruby(<<~RUBY)
      require "rails"
      require "activerecord-mysql-rgeo"

      class Application < Rails::Application
        config.eager_load = false
        config.logger = Logger.new(nil)
        config.secret_key_base = "secret"
      end
      Application.initialize!
      print Rails.application.deprecators[:activerecord_mysql_rgeo].equal?(ActiveRecord::MysqlRgeo.deprecator)
    RUBY

    expect(status).to be_success, errors
    expect(output).to eq("true")
  end
end
