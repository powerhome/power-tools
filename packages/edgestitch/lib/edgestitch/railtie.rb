# frozen_string_literal: true

require "edgestitch"

module Edgestitch
  # Railtie to install the stitch task (db:stitch).
  # require this railtie to automatically install the stitch task for the app,
  # or define it manually adding `::Edgestitch.define_stitch` to your Rakefile.
  class Railtie < ::Rails::Railtie
    rake_tasks { ::Edgestitch::Tasks.define_stitch }
  end
end
