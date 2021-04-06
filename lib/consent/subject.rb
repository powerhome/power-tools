# frozen_string_literal: true

module Consent
  class Subject # :nodoc:
    attr_reader :key, :label, :actions, :views

    def initialize(key, label)
      @key = key
      @label = label
      @actions = []
      @views = Consent.default_views.clone
    end

    def view_for(action, key)
      view = @views.keys & action.view_keys & [key]
      @views[view.first] || @views[action.default_view]
    end
  end
end
