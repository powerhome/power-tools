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

    def to_permission_payload
      {
        subject: key,
        label: label,
        actions: actions.map(&:to_permission_payload),
        views: views.values.map(&:to_permission_payload),
      }
    end
  end
end
