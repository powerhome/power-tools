# frozen_string_literal: true

require "minitest"
require "yaml"

module Regression
  # Skips the Active Record tests listed in regression/excludes.yml that apply
  # to the current adapter and Active Record version. Runs as a Minitest plugin,
  # after every test file has been loaded, and turns each listed test into a
  # skip that prints its reason.
  module Excludes
    FILE = File.expand_path("excludes.yml", __dir__)

  module_function

    def apply(adapter, activerecord_version)
      YAML.load_file(FILE).each do |entry|
        next unless applies?(entry, adapter, activerecord_version)

        entry.fetch("tests").each do |test|
          skip_test(*test.split("#", 2), entry.fetch("reason"))
        end
      end
    end

    def applies?(entry, adapter, activerecord_version)
      entry.fetch("adapters", [adapter]).include?(adapter) &&
        Gem::Requirement.new(entry.fetch("activerecord", ">= 0")).satisfied_by?(activerecord_version)
    end

    def skip_test(class_name, test_name, reason)
      test_class = Object.const_get(class_name)
      unless test_class.method_defined?(test_name)
        raise ArgumentError, "regression/excludes.yml lists #{class_name}##{test_name}, which does not exist"
      end

      test_class.define_method(test_name) { skip(reason) }
    end
  end
end

module Minitest
  def self.plugin_regression_excludes_init(_options)
    Regression::Excludes.apply(ENV.fetch("ARCONN"), ActiveRecord.gem_version)
  end
end

Minitest.extensions << "regression_excludes"
