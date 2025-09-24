# frozen_string_literal: true

module TwoPercent
  class UpdateEvent < ApplicationEvent
    event_name "update.all"
    event_name { "update.#{resource}" }

    attribute :resource
    attribute :id
    attribute :params
  end
end
