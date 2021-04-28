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

    def view_keys
      @options.fetch(:views, [])
    end

    def default_view
      @options[:default_view]
    end
  end
end
