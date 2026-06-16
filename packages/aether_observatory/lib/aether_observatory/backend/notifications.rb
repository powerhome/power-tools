# frozen_string_literal: true

module AetherObservatory
  module Backend
    module Notifications
    module_function

      def instrument(event)
        event.names.each do |event_name|
          ActiveSupport::Notifications.instrument(event_name, event)
        end
      end

      def subscribe(topic, event, *_args)
        ActiveSupport::Notifications.subscribe(topic) do |*args|
          event.name.constantize.new(ActiveSupport::Notifications::Event.new(*args)).process
        end
      end

      def unsubscribe(topic)
        ActiveSupport::Notifications.unsubscribe(topic)
      end
    end
  end
end
