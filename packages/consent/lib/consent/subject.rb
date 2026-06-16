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
      actions = self.actions.sort
      views = self.views.values.sort
      {
        subject: key,
        label: label,
        actions: actions.map(&:to_permission_payload),
        views: views.map(&:to_permission_payload),
      }
    end

    def <=>(other)
      key = Consent::SubjectCoder.dump(key)
      other_key = Consent::SubjectCoder.dump(other.key)
      key <=> other_key
    end
  end
end
