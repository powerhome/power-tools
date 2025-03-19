# frozen_string_literal: true

require "spec_helper"

module AetherObservatory
  RSpec.describe EventBase do
    describe ".create" do
      it "sends event to a single observer" do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        observer =
          a_started_observer(
            name: "zero",
            listening_to: ["#{prefix}.zero"]
          )

        # When
        event.create!(message: "message")

        # Then
        expect(observer.returned_payload.message).to eq("message")

        # Teardown
        observer.stop
      end

      it "sends event to multiple observers", :aggregate_failures do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "zero", prefix: prefix)
        observer_zero =
          a_started_observer(
            name: "zero",
            listening_to: ["#{prefix}.zero"]
          )
        observer_both =
          a_started_observer(
            name: "both",
            listening_to: ["#{prefix}.zero", "#{prefix}.one"]
          )

        # When
        event.create!(message: "message")

        # Then
        expect(observer_zero.returned_payload.message).to eq("message")
        expect(observer_both.returned_payload.message).to eq("message")

        # Teardown
        observer_zero.stop
        observer_both.stop
      end

      it "sends event to only one of multiple observers", :aggregate_failures do
        # Given
        prefix = "fake_prefix"
        event = a_fake_event(named: "one", prefix: prefix)
        observer_zero =
          a_started_observer(
            name: "zero",
            listening_to: ["#{prefix}.zero"]
          )
        observer_both =
          a_started_observer(
            name: "both",
            listening_to: ["#{prefix}.zero", "#{prefix}.one"]
          )

        # When
        event.create!(message: "message")

        # Then
        expect(observer_zero.returned_payload).to eq(nil)
        expect(observer_both.returned_payload.message).to eq("message")

        # Teardown
        observer_zero.stop
        observer_both.stop
      end

      context "without a prefix" do
        it "processes a single event" do
          # Given
          event = a_fake_event(named: "zero", prefix: nil)
          observer =
            a_started_observer(
              name: "zero",
              listening_to: ["zero"]
            )

          # When
          event.create!(message: "message")

          # Then
          expect(observer.returned_payload.message).to eq("message")

          # Teardown
          observer.stop
        end
      end
    end

  private

    def a_fake_event(prefix:, named: "event_name")
      stub_const(
        "FakeEventTopic#{named.capitalize}",
        Class.new(EventBase) do
          attribute :message
          event_prefix prefix if prefix.present?
          event_name { named }
        end
      )
    end

    def a_started_observer(**kwargs)
      a_fake_observer(**kwargs).tap(&:start)
    end

    def a_fake_observer(name:, listening_to: [])
      stub_const(
        name.classify,
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
  end
end
