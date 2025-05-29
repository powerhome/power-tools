# frozen_string_literal: true

require "active_model"

module AetherObservatory
  class EventBase
    include ActiveModel::AttributeAssignment
    include ActiveModel::Attributes

    class_attribute :backend, default: AetherObservatory::Backend::Notifications

    class << self
      def inherited(subclass)
        super
        subclass.event_prefix(&event_prefix)
      end

      def create(**attributes)
        backend.instrument new(**attributes)

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

        @logger || AetherObservatory.config.logger || Logger.new(nil)
      end
    end

    delegate :event_name, to: "self.class"
    delegate :logger, to: "self.class"

    def initialize(attributes = {})
      super()
      assign_attributes(attributes) if attributes
    end

    def names
      prefix = instance_exec(&self.class.event_prefix) if self.class.event_prefix
      self.class.event_names.map do |event_name|
        [prefix, instance_exec(&event_name)].compact.join(".")
      end
    end
  end
end
