# frozen_string_literal: true

module TwoPercent
  class DeleteEvent < ApplicationEvent
    event_name "delete.all"
    event_name { "delete.#{resource}" }

    attribute :resource
    attribute :id
  end
end
