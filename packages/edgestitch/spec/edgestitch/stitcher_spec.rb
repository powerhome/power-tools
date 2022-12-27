# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edgestitch::Stitcher do
  let(:stitcher) { Edgestitch::Stitcher.new([Sales::Engine, Payroll::Engine]) }
  subject { stitcher.render }

  it "renders tables from all given components" do
    expect(subject).to include("spec/dummy/engines/sales/db/structure-self.sql").once
    expect(subject).to include("CREATE TABLE `sales_prices`").once
    expect(subject).to include("spec/dummy/engines/payroll/db/structure-self.sql").once
    expect(subject).to include("CREATE TABLE `payroll_salaries` (").once
    expect(subject).to include("CREATE TABLE `payroll_ghosts` (").once
    expect(subject).to include("CREATE TABLE").exactly(4).times
  end

  it "renders a single schema_migrations table" do
    expect(subject).to include("CREATE TABLE IF NOT EXISTS `schema_migrations`").once
  end

  it "includes insert statements for the migrations of the given components" do
    expect(subject).to include("INSERT INTO `schema_migrations` VALUES").twice
    expect(subject).to include("20221219191938").once
    expect(subject).to include("20221219195431").once
    expect(subject).to include("20221221142539").once
  end
end
