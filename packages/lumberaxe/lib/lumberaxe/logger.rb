# frozen_string_literal: true

module Lumberaxe
  class Logger < ::ActiveSupport::Logger
    cattr_accessor(:log_level) { :debug }

    def initialize(output = $stdout, progname:, level: log_level)
      super output

      self.progname = progname
      self.level = level

      self.formatter = JSONFormatter.new
      extend ActiveSupport::TaggedLogging
      extend ActiveSupport::LoggerSilence
    end
  end
end
