# frozen_string_literal: true

require "spec_helper"
require "data_taster/detergent_row_interpolator"

RSpec.describe DataTaster::DetergentRowInterpolator do
  describe ".substitute" do
    let(:client) { double("client", escape: ->(s) { s }) }

    it "replaces longer identifier names before shorter ones" do
      row = { "id" => 1, "identity" => 99 }
      expression = "CONCAT(id, '-', identity)"

      expect(described_class.substitute(expression, row, client)).to eq("CONCAT(1, '-', 99)")
    end

    it "leaves non-identifier tokens unchanged" do
      row = { "id" => 5 }
      expression = "CONCAT('users_', id, '@nitrophrg.com')"

      expect(described_class.substitute(expression, row, client)).to eq("CONCAT('users_', 5, '@nitrophrg.com')")
    end
  end
end
