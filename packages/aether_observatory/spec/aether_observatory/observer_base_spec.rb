# frozen_string_literal: true

require "spec_helper"

module AetherObservatory
  RSpec.describe ObserverBase do
    describe "#process" do
      it "processes a single event" do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        observer = a_fake_observer(listening_to: ["#{prefix}.zero"])

        # When
        observer.start
        event.create(message: "message")

        # Then
        expect(observer.returned_payload.message).to eq("message")

        # Teardown
        observer.stop
      end

      it "processed multiple events", :aggregate_failures do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        other_event = a_fake_event(named: "one", prefix: prefix)
        observer = a_fake_observer(listening_to: ["#{prefix}.zero", "#{prefix}.one"])

        # When
        observer.start
        event.create(message: "message zero")

        # Then
        expect(observer.returned_payload.message).to eq("message zero")

        # When
        other_event.create(message: "message one")

        # Then
        expect(observer.returned_payload.message).to eq("message one")

        # Teardown
        observer.stop
      end
    end

    describe "#stop" do
      it "event is not processed" do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        observer = a_fake_observer(listening_to: ["#{prefix}.zero"])

        # When
        observer.stop
        event.create(message: "message")

        # Then
        expect(observer.returned_payload).to eq(nil)

        # Teardown
        observer.stop
      end
    end

    describe "#start" do
      it "event is processed" do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        observer = a_fake_observer(listening_to: ["#{prefix}.zero"])

        # When
        observer.start
        event.create(message: "message")

        # Then
        expect(observer.returned_payload.message).to eq("message")

        # Teardown
        observer.stop
      end

      context "when the observer class is reloaded (simulating Rails code reload)" do
        it "does not accumulate duplicate subscriptions" do
          # Given
          prefix = "fake_prefix"
          event = a_fake_event(named: "zero", prefix: prefix)

          # First "boot": define and start the observer
          observer_v1 = a_fake_observer(listening_to: ["#{prefix}.zero"])
          observer_v1.start

          # Simulate Rails reload: re-evaluate the class definition under the same
          # constant. The new class gets fresh @state: stopped and @subscriptions: {},
          # but the subscription registered by observer_v1 is still live in
          # ActiveSupport::Notifications.
          observer_v2 = a_fake_observer(listening_to: ["#{prefix}.zero"])
          observer_v2.start

          event.create(message: "message")

          # process must fire exactly once, not twice
          expect(observer_v2.process_count).to eq(1)

          # Teardown
          observer_v2.stop
        end
      end
    end

  private

    def a_fake_event(named: "event_name", prefix: "fake_test_topic")
      stub_const(
        "FakeEventTopic#{named.capitalize}",
        Class.new(EventBase) do
          attribute :message
          event_prefix prefix
          event_name { named }
        end
      )
    end

    def a_fake_observer(listening_to: [])
      stub_const(
        "FakeObserver",
        Class.new(ObserverBase) do
          class << self
            attr_accessor :returned_payload
            attr_accessor :process_count
          end

          self.process_count = 0

          listening_to.each { |event_name| subscribe_to(event_name) }

          def process
            self.class.returned_payload = event_payload
            self.class.process_count += 1
          end
        end
      )
    end
  end
end
