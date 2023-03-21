# frozen_string_literal: true

class TruckWithoutHistoryOptions < ApplicationRecord
  include CamelTrail::Recordable
  self.table_name = "trucks"
end
