# frozen_string_literal: true

require "active_model"

module AetherObservatory
  class EventBase
    include ActiveModel::AttributeAssignment
    include ActiveModel::Attributes

    class << self
      def inherited(subclass)
        super
        subclass.event_prefix(&event_prefix)
      end

      def create(**attributes)
        event = new(**attributes)
        event_names_with_prefix.each do |event_name_parts|
          event_name = event_name_parts.filter_map do |part|
            event.instance_exec(&part) unless part.nil?
          end.join(".")
          logger.debug("[#{name}] Create event for topic: [#{event_name}]")
          ActiveSupport::Notifications.instrument(event_name, event)
        end

        nil
      end

      def event_prefix(value = nil, &block)
        @event_prefix = -> { value } if value.present?
        @event_prefix = block if block.present?

        @event_prefix
      end

      def event_name(value = nil, &block)
        event_names << -> { value } if value.present?
        event_names << block if block.present?

        nil
      end

      def event_names_with_prefix
        event_names.map { |event_name| [event_prefix, event_name] }
      end

      def event_names
        @event_names ||= []
      end

      def logger(value = nil)
        @logger = value if value.present?

        @logger || AetherObservatory.config.logger
      end
    end

    delegate :event_name, to: "self.class"
    delegate :logger, to: "self.class"

    def initialize(attributes = {})
      super()
      assign_attributes(attributes) if attributes
    end
  end
end
