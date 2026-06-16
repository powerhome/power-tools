# frozen_string_literal: true

require "camel_trail"

class Truck < ApplicationRecord
  include CamelTrail::Recordable

  history_options(source_changes: :history_changes)

private

  def history_changes
    saved_changes.tap do |changes|
      changes[:price][1] = 0 if saved_change_to_price? && price.negative?
    end
  end
end
