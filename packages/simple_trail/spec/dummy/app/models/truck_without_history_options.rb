# frozen_string_literal: true

class TruckWithoutHistoryOptions < ApplicationRecord # rubocop:disable NitroComponent/Inheritance
  include SimpleTrail::Recordable
  self.table_name = "trucks"
end
