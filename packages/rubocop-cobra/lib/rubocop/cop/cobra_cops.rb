# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      require_relative "cobra/association_class"
      require_relative "cobra/component_gemfile"
      require_relative "cobra/component_gemspec"
      require_relative "cobra/constant_resolution"
      require_relative "cobra/deprecation_list"
      require_relative "cobra/file_placement_help"
      require_relative "cobra/gemspec_dependencies"
      require_relative "cobra/path_block_insertion"

      require_relative "cobra/command_file_placement"
      require_relative "cobra/controller_file_placement"
      require_relative "cobra/dependency_version"
      require_relative "cobra/deprecated_constant"
      require_relative "cobra/engine_isolate_namespace"
      require_relative "cobra/gem_requirement"
      require_relative "cobra/inheritance"
      require_relative "cobra/job_file_placement"
      require_relative "cobra/lib_file_placement"
      require_relative "cobra/mailer_file_placement"
      require_relative "cobra/model_file_placement"
      require_relative "cobra/presenter_file_placement"
      require_relative "cobra/synced_dependency_declaration"
      require_relative "cobra/view_component_file_placement"
    end
  end
end
