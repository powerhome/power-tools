# frozen_string_literal: true

module Consent
  class Action # :nodoc:
    attr_reader :subject, :key, :label, :options

    def initialize(subject, key, label, options = {})
      @subject = subject
      @key = key
      @label = label
      @options = options
    end

    def views
      @views ||= @subject.views.slice(*@options.fetch(:views, []))
    end

    def default_view
      return unless @options.key?(:default_view)

      @default_view ||= @subject.views[@options[:default_view]]
    end

    def to_permission_payload
      views = self.views.values.sort
      {
        action: key,
        label: label,
        views: views.map(&:to_permission_payload),
        options: options.except(:views),
        default_view: default_view&.to_permission_payload,
      }
    end

    def <=>(other)
      key.to_s <=> other.key.to_s
    end
  end
end
