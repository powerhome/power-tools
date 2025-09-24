# frozen_string_literal: true

module TwoPercent
  class CreateEvent < ApplicationEvent
    event_name "create.all"
    event_name { "create.#{resource}" }

    attribute :resource
    attribute :params
  end
end
