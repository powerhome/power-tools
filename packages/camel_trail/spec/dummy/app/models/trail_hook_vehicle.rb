# frozen_string_literal: true

require "camel_trail"

class TrailHookVehicle < ApplicationRecord
  include CamelTrail::Recordable

  attr_accessor :skip_camel_trail

protected

  def camel_trail_activity_for_save(default_activity)
    activity.presence || default_activity
  end

  def camel_trail_note_for_save
    note
  end

  def skip_camel_trail_auto_record?
    skip_camel_trail == true
  end
end
