module Consent
  class Permission
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

    def view_key
      @view && @view.key
    end

    def conditions(*args)
      @view && @view.conditions(*args)
    end

    def object_conditions(*args)
      @view && @view.object_conditions(*args)
    end
  end
end
