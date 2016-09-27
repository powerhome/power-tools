module Nitro
  module Consent
    class Subject
      attr_reader :key, :label, :actions

      def initialize(key, label)
        @key = key
        @label = label
        @actions = []
      end

      def permission_key
        ActiveSupport::Inflector.underscore(@key.to_s).to_sym
      end

      def views
        @views ||= Nitro::Consent.default_views.clone
      end

      def add_action(*attrs)
        @actions << Action.new(self, *attrs)
      end

      def conditions(view, *args)
        views[view.to_sym] && views[view.to_sym].conditions(*args)
      end
    end
  end
end
