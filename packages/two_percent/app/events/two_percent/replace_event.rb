# frozen_string_literal: true

module TwoPercent
  class ReplaceEvent < ApplicationEvent
    event_name "replace.all"
    event_name { "replace.#{resource}" }

    attribute :resource
    attribute :id
    attribute :params
  end
end
