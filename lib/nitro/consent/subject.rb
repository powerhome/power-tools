module Nitro
  module Consent
    class Subject
      attr_reader :key, :label, :options

      def initialize(key, label, options)
        @key = key
        @label = label
        @options = options
      end

      def permission_key
        ActiveSupport::Inflector.underscore(@key.to_s).to_sym
      end

      def options
        super || {}
      end

      def views
        @views ||= Nitro::Consent.default_views.clone
      end

      def actions
        @actions ||= {}
      end

      def conditions(view, *args)
        views[view.to_sym] && views[view.to_sym].conditions(*args)
      end
    end
  end
end
