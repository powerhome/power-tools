# frozen_string_literal: true

module Consent
  class Permission # :nodoc:
    attr_reader :subject_key, :action_key, :view_key, :view

    def initialize(subject_key, action_key, view_key = nil)
      @subject_key = subject_key
      @action_key = action_key
      @view_key = view_key
      @view = Consent.find_view(subject_key, view_key) if view_key
    end

    def action
      @action ||= Consent.find_action(subject_key, action_key)
    end

    def valid?
      action && (@view_key.nil? == @view.nil?)
    end

    def conditions(*args)
      @view.nil? ? nil : @view.conditions(*args)
    end

    def object_conditions(*args)
      @view.nil? ? nil : @view.object_conditions(*args)
    end
  end
end
