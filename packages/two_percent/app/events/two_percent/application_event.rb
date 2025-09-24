# frozen_string_literal: true

module TwoPercent
  class ApplicationEvent < AetherObservatory::EventBase
    event_prefix "two_percent.scim"
  end
end
