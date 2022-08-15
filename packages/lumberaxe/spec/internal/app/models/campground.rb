# frozen_string_literal: true

class Campground < ApplicationRecord
  self.table_name = "internal_campgrounds"

  validates :name, presence: true
end
