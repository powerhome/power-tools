module Consent
  class Action
    attr_reader :key, :label, :options

    def initialize(key, label, options = {})
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
