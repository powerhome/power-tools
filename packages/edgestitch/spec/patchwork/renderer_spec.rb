# frozen_string_literal: true

require "rails_helper"

RSpec.describe Edgestitch::Renderer do
  before do
    Rails.application.eager_load!
  end

  let(:renderer) { Edgestitch::Renderer.new([Sales::Engine, Payroll::Engine]) }

  it "renders tables from all given components" do
    expect(renderer.render).to include("spec/dummy/engines/sales/db/structure-self.sql").once
    expect(renderer.render).to include("CREATE TABLE `sales_prices`").once
    expect(renderer.render).to include("spec/dummy/engines/payroll/db/structure-self.sql").once
    expect(renderer.render).to include("CREATE TABLE `payroll_salaries` (").once
    expect(renderer.render).to include("CREATE TABLE `tags` (").once
    expect(renderer.render).to include("CREATE TABLE `taggings` (").once
    expect(renderer.render).to include("CREATE TABLE").exactly(5).times
  end

  it "renders a single schema_migrations table" do
    expect(renderer.render).to include("CREATE TABLE IF NOT EXISTS `schema_migrations`").once
  end

  it "includes insert statements for the migrations of the given components" do
    expect(renderer.render).to include("INSERT INTO `schema_migrations` VALUES").twice
    expect(renderer.render).to include("20221219191938").once
    expect(renderer.render).to include("20221219195431").once
    expect(renderer.render).to include("20221219231318").once
    expect(renderer.render).to include("20221219231320").once
    expect(renderer.render).to include("20221219231322").once
    expect(renderer.render).to include("20221219231323").once
    expect(renderer.render).to include("20221219231324").once
  end
end
