# frozen_string_literal: true

module Consent
  class Permission # :nodoc:
    attr_reader :subject_key, :action_key, :view_key
    delegate :conditions, :object_conditions, to: :@view, allow_nil: true

    def initialize(subject_key, action_key, view_key = nil)
      @subject_key = subject_key
      @action_key = action_key
      @view_key = view_key
      @view = Consent.find_view(subject_key, view_key) if view_key
    end
  end
end
