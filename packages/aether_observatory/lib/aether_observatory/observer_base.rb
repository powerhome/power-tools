# frozen_string_literal: true

module AetherObservatory
  class ObserverBase
    class_attribute :backend, default: AetherObservatory::Backend::Notifications

    class << self
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@subscribed_topics, Set.new)
        subclass.instance_variable_set(:@state, :stopped)
        subclass.instance_variable_set(:@subscriptions, {})
      end

      def start
        return if started?

        logger.debug("[#{name}] Starting")

        subscribed_to.each do |topic|
          next if subscriptions.include?(topic)

          register_subscription_to(topic)
        end

        self.state = :started
      end

      def stop
        return if stopped?

        logger.debug("[#{name}] Stopping")

        subscriptions.each_key do |topic|
          unregister_subscription_to(topic)
        end

        self.state = :stopped
      end

      def subscribe_to(topic)
        subscribed_topics.add(topic)

        return if stopped?

        register_subscription_to(topic)
      end

      def unsubscribe_from(topic)
        subscribed_topics.delete(topic)

        return if stopped?

        unregister_subscription_to(topic)
      end

      def subscribed_to
        subscribed_topics.to_a
      end

      def started?
        state == :started
      end

      def stopped?
        state == :stopped
      end

    private

      attr_reader :subscribed_topics, :subscriptions
      attr_accessor :state

      def register_subscription_to(topic)
        return if subscriptions.include?(topic)

        logger.debug("[#{name}] Registering subscription to topic: #{topic.inspect}")

        subscriptions[topic] = backend.subscribe(topic, self)
      end

      def unregister_subscription_to(topic)
        return if subscriptions.exclude?(topic)

        logger.debug("[#{name}] Unregistering subscription to topic: #{topic.inspect}")

        backend.unsubscribe(subscriptions.delete(topic))
      end

      def logger(value = nil)
        @logger = value if value.present?

        @logger || AetherObservatory.config.logger
      end
    end

    attr_accessor :event

    def initialize(event)
      self.event = event
    end

    delegate :name, to: :event, prefix: true
    delegate :payload, to: :event, prefix: true
  end
end
