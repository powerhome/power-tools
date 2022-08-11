# frozen_string_literal: true

module Lumberaxe
  class Logger < ::ActiveSupport::Logger
    def initialize(output = $stdout, level:, progname:)
      super output

      self.progname = progname
      self.level = level

      self.formatter = JSONFormatter.new
      extend ActiveSupport::TaggedLogging
    end
  end
end
