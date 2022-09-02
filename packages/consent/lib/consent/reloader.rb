# frozen_string_literal: true

module Consent
  # Rails file reloader to detect permission changes and apply them to consent
  # @private
  class Reloader
    attr_reader :paths

    delegate :updated?, :execute, :execute_if_updated, to: :updater

    def initialize(default_path)
      @paths = [default_path]
    end

  private

    def reload!
      Consent.subjects.clear
      Consent.load_subjects! paths
    end

    def updater
      @updater ||= ActiveSupport::FileUpdateChecker.new([], globs) { reload! }
    end

    def globs
      pairs = paths.map { |path| [path.to_s, %w[rb]] }
      pairs.to_h
    end
  end
end
