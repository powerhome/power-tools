module Nitro
  module Consent
    class Permission
      def initialize(subject, action, view)
        @subject = subject
        @action = action
        @view = view
      end

      def subject_key
        @subject.key
      end

      def action_key
        @action.key
      end

      def view_key
        @view
      end

      def conditions(*args)
        view = @subject.view_for(@action, view_key)
        view && view.conditions(*args)
      end
    end
  end
end
