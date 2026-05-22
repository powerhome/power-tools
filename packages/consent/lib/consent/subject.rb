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

    def to_h
      {
        subject: key,
        label: label,
        actions: actions.map(&:to_h),
        views: views.values.map(&:to_h),
      }
    end
  end
end
