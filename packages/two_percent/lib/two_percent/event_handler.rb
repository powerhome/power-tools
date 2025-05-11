# frozen_string_literal: true

module TwoPercent
  class EventHandler
    def self.dispatch(method, **attrs)
      EventHandler.new(method).dispatch(**attrs)
    end

    METHOD_EVENT = {
      "POST" => "TwoPercent::CreateEvent",
      "PATCH" => "TwoPercent::UpdateEvent",
      "PUT" => "TwoPercent::ReplaceEvent",
      "DELETE" => "TwoPercent::DeleteEvent",
    }.freeze

    def initialize(method)
      @event = METHOD_EVENT.fetch(method) do
        raise "Invalid method #{method}"
      end.constantize
    end

    def dispatch(**attrs)
      @event.create(**attrs)
    end
  end
end
