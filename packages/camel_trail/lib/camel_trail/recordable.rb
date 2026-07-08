# frozen_string_literal: true

module CamelTrail
  module Recordable
    extend ActiveSupport::Concern

    included do
      around_save :__record_changes
    end

    class_methods do
      attr_reader :__camel_trail_source_changes

      def history_options(source_changes: nil)
        @__camel_trail_source_changes = source_changes
      end
    end

  protected

    def camel_trail_activity_for_save(default_activity)
      default_activity
    end

    def camel_trail_note_for_save
      nil
    end

    def skip_camel_trail_auto_record?
      false
    end

  private

    def __record_changes
      default_activity = new_record? ? :created : :updated
      yield

      return if saved_changes.blank?
      return if skip_camel_trail_auto_record?

      activity = camel_trail_activity_for_save(default_activity)
      note = camel_trail_note_for_save

      CamelTrail.record!(self, activity, __camel_trail_source_changes,
                         CamelTrail::Config.current_session_user_id&.call, note)
    end

    def __camel_trail_source_changes
      source_changes = self.class.__camel_trail_source_changes

      case source_changes
      when Proc then instance_exec(&source_changes)
      when Symbol then send(source_changes)
      else saved_changes
      end
    end
  end
end
