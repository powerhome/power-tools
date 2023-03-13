# frozen_string_literal: true

module NitroHistory
  module Recordable
    extend ActiveSupport::Concern

    included do
      around_save :__record_changes
    end

    class_methods do
      attr_reader :__nitro_history_source_changes

      def history_options(source_changes: nil)
        @__nitro_history_source_changes = source_changes
      end
    end

  private

    def __record_changes
      activity = new_record? ? :created : :updated
      yield
      NitroHistory.record!(self, activity, __nitro_history_source_changes, NitroAuth.current_session_user_id)
    end

    def __nitro_history_source_changes
      source_changes = self.class.__nitro_history_source_changes

      case source_changes
      when Proc then instance_exec(&source_changes)
      when Symbol then send(source_changes)
      else saved_changes
      end
    end
  end
end
