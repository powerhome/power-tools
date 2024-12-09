# frozen_string_literal: true

require "spec_helper"

module AetherObservatory
  RSpec.describe ObserverBase do
    after(:each) { teardown }

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
          end

          listening_to.each { |event_name| subscribe_to(event_name) }

          def process
            self.class.returned_payload = event_payload
          end
        end
      )
    end

    def teardown
      ActiveSupport::Notifications.notifier =
        ActiveSupport::Notifications::Fanout.new
    end
  end
end
