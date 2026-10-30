# frozen_string_literal: true

require "open3"

RSpec.describe ActiveRecord::MysqlRgeo do
  it "has a version number" do
    expect(ActiveRecord::MysqlRgeo::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  it "does not load a MySQL driver by itself" do
    script = 'require "activerecord-mysql-rgeo"; print [defined?(::Trilogy), defined?(::Mysql2)].inspect'
    output, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-rbundler/setup", "-e", script)

    expect(status).to be_success, output
    expect(output).to eq("[nil, nil]")
  end
end
