# frozen_string_literal: true

class Truck < ApplicationRecord # rubocop:disable NitroComponent/Inheritance
  include NitroHistory::Recordable
  history_options(source_changes: :history_changes)

private

  def history_changes
    saved_changes.tap do |changes|
      changes[:price][1] = 0 if saved_change_to_price? && price.negative?
    end
  end
end
