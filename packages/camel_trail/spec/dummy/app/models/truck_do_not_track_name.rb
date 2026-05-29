# frozen_string_literal: true

require "camel_trail"

class TruckDoNotTrackName < ApplicationRecord
  self.table_name = 'trucks'

  include CamelTrail::Recordable

  history_options(source_changes: :omit_name_changes)

private

  def omit_name_changes
    saved_changes.except(:name)
  end
end
