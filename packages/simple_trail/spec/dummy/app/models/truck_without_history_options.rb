# frozen_string_literal: true

class TruckWithoutHistoryOptions < ApplicationRecord
  include SimpleTrail::Recordable
  self.table_name = "trucks"
end
