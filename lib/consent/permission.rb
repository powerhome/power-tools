# frozen_string_literal: true

module Consent
  class Permission # :nodoc:
    def initialize(subject, action, view = nil)
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

    # Disables Sytle/SafeNavigation to keep this code
    # compatible with ruby < 2.3
    # rubocop:disable Style/SafeNavigation
    def view_key
      @view && @view.key
    end

    def conditions(*args)
      @view && @view.conditions(*args)
    end

    def object_conditions(*args)
      @view && @view.object_conditions(*args)
    end
    # rubocop:enable Style/SafeNavigation
  end
end
