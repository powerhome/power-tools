# frozen_string_literal: true

module AetherObservatory
  module Backend
    module Memory
    module_function

      def instrumented
        @instrumented ||= []
      end

      def subscribed
        @subscribed ||= {}
      end

      def instrument(event)
        instrumented << event
      end

      def subscribe(topic, event)
        subscribed[topic] ||= []
        subscribed[topic] << event
      end

      def unsubscribe(topic)
        subscribed.delete(topic)
      end
    end
  end
end
