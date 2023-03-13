# frozen_string_literal: true

class TruckWithoutHistoryOptions < ApplicationRecord # rubocop:disable NitroComponent/Inheritance
  include NitroHistory::Recordable
  self.table_name = "trucks"
end
