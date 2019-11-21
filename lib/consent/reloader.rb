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
      @updater ||= begin
        updater = ActiveSupport::FileUpdateChecker.new([], watch_dirs) { reload! }
        updater.tap(&:execute)
      end
    end

    def watch_dirs
      pairs = paths.map { |path| [path.to_s, %w[rb]] }
      Hash[pairs]
    end
  end
end
