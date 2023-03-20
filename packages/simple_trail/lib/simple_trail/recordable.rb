# frozen_string_literal: true

module SimpleTrail
  module Recordable
    extend ActiveSupport::Concern

    included do
      around_save :__record_changes
    end

    class_methods do
      attr_reader :__simple_trail_source_changes

      def history_options(source_changes: nil)
        @__simple_trail_source_changes = source_changes
      end
    end

  private

    def __record_changes
      activity = new_record? ? :created : :updated
      yield
      SimpleTrail.record!(self, activity, __simple_trail_source_changes,
                          SimpleTrail::Config.current_session_user_id&.call)
    end

    def __simple_trail_source_changes
      source_changes = self.class.__simple_trail_source_changes

      case source_changes
      when Proc then instance_exec(&source_changes)
      when Symbol then send(source_changes)
      else saved_changes
      end
    end
  end
end
