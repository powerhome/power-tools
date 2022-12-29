# frozen_string_literal: true

module Lumberaxe
  class TaggedLogging
    include ActiveSupport::LoggerSilence
    include ActiveSupport::TaggedLogging

    def self.new(logger)
      extend ActiveSupport::LoggerSilence
      extend ActiveSupport::TaggedLogging

      super
    end
  end
end
