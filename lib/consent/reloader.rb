module Consent
  # Rails file reloader to detect permission changes and apply them to consent
  class Reloader
    attr_reader :paths
    delegate :updated?, :execute, :execute_if_updated, to: :updater

    def initialize(default_path, mechanism)
      @paths = [default_path]
      @mechanism = mechanism
    end

    private

    def reload!
      Consent.subjects.clear
      Consent.load_subjects! paths, @mechanism
    end

    def updater
      @updater ||= ActiveSupport::FileUpdateChecker.new([], globs) { reload! }
    end

    def globs
      pairs = paths.map { |path| [path.to_s, %w[rb]] }
      Hash[pairs]
    end
  end
end
