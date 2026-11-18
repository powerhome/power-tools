# frozen_string_literal: true

require "fileutils"
require "pathname"
require "rake/file_list"
require "rake/file_utils"

module Regression
  # Runs Active Record's own test suite for one MySQL driver with this gem
  # loaded, proving the gem leaves non-spatial behaviour untouched.
  #
  # The published activerecord gem does not ship its tests, so they are checked
  # out from the Rails repository at the tag matching the bundled activerecord,
  # or at the locked revision when activerecord comes from git. The checkout
  # always lives outside the gem directories: Rails' backtrace cleaner hides gem
  # paths, and some tests assert on their own file locations.
  class Suite
    include FileUtils

    RAILS_REPOSITORY = "https://github.com/rails/rails.git"
    ROOT = Pathname.new(__dir__).parent

    def initialize(adapter)
      @adapter = adapter
    end

    # Runs from the activerecord checkout, like Rails' own `rake test:<adapter>`:
    # the tests write logs and SQLite databases relative to it.
    def run
      sh({ "ARCONN" => @adapter, "ARCONFIG" => ROOT.join("regression/config.yml").to_s },
         Gem.ruby, "-I#{test_root}", "-I#{ROOT.join('lib')}", "-r#{ROOT.join('regression/helper')}",
         test_loader, *test_files, chdir: activerecord_root.to_s)
    end

  private

    # Same selection as Rails' `rake test:<adapter>` in activerecord/Rakefile.
    def test_files
      Dir.chdir(activerecord_root) do
        cases = Rake::FileList["test/cases/**/*_test.rb"].reject do |file|
          file.include?("/adapters/") || file.include?("/encryption/performance")
        end
        cases += Rake::FileList["test/cases/adapters/{#{@adapter},abstract_mysql_adapter}/**/*_test.rb"]
        cases.map { |file| activerecord_root.join(file).to_s }
      end
    end

    def test_root
      activerecord_root.join("test")
    end

    def test_loader
      Gem.find_files("rake/rake_test_loader.rb").first
    end

    def activerecord_root
      @activerecord_root ||= checkout_activerecord
    end

    def checkout_activerecord
      checkout = ROOT.join("tmp/rails", rails_ref)
      fetch_rails(checkout) unless checkout.join("activerecord/test/cases").directory?
      checkout.join("activerecord")
    end

    def fetch_rails(checkout)
      rm_rf checkout
      mkdir_p checkout
      git = ["git", "-C", checkout.to_s]
      sh(*git, "init", "--quiet")
      sh(*git, "sparse-checkout", "set", "activerecord/test", "tools")
      sh(*git, "fetch", "--quiet", "--depth=1", "--filter=blob:none", RAILS_REPOSITORY, rails_ref)
      sh(*git, "checkout", "--quiet", "FETCH_HEAD")
    end

    # The locked git revision for edge, the release tag otherwise.
    def rails_ref
      source = activerecord_spec.source
      source.respond_to?(:revision) ? source.revision : "v#{activerecord_spec.version}"
    end

    def activerecord_spec
      Gem.loaded_specs.fetch("activerecord")
    end
  end
end
