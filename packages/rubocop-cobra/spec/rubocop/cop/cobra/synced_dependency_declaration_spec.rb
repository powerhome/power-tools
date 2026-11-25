# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe RuboCop::Cop::Cobra::SyncedDependencyDeclaration do
  subject(:cop) { described_class.new }

  let(:components) { File.join(@root, "components") }
  let(:gemfile) { File.join(components, "my_component", "Gemfile") }

  around do |example|
    Dir.mktmpdir do |root|
      @root = root
      %w[directory nitro_jobs nitro_linting nitro_react].each { |name| write_gemspec(name) }
      example.run
    end
  end

  def write_gemspec(name, deps: [], dev_deps: [], component: name, file: name)
    dir = File.join(components, component)
    FileUtils.mkdir_p(dir)
    lines = deps.map { |dep| %(  s.add_dependency "#{dep}", "0.0.1") } +
            dev_deps.map { |dep| %(  s.add_development_dependency "#{dep}", "0.0.1") }
    File.write(File.join(dir, "#{file}.gemspec"), <<~RUBY)
      Gem::Specification.new do |s|
        s.name = "#{name}"
      #{lines.join("\n")}
      end
    RUBY
  end

  def write_component_gemspec(...)
    write_gemspec("my_component", ...)
  end

  context "does not register an offense" do
    it "when the block lists exactly the sibling components the gemspec declares" do
      write_component_gemspec(deps: %w[directory nitro_react rails], dev_deps: %w[nitro_linting rspec])

      expect_no_offenses(<<~RUBY, gemfile)
        source "https://rubygems.org"

        gemspec

        path ".." do
          # Dependencies on other components go here
          gem "directory", require: nil
          gem "nitro_linting", require: nil
          gem "nitro_react", require: nil
        end

        gem "vite_ruby", "3.8.0"
      RUBY
    end

    it "when the Gemfile has no path block" do
      write_component_gemspec(deps: %w[directory])

      expect_no_offenses(<<~RUBY, gemfile)
        gemspec

        gem "directory", path: "../directory"
      RUBY
    end

    it "when the Gemfile does not call gemspec" do
      write_component_gemspec(deps: %w[directory])

      expect_no_offenses(<<~RUBY, gemfile)
        path ".." do
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when there are several gemspecs and gemspec does not name one" do
      write_component_gemspec(deps: %w[directory])
      write_gemspec("my_component_extras", component: "my_component")

      expect_no_offenses(<<~RUBY, gemfile)
        gemspec

        path ".." do
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when the gemspec does not exist" do
      expect_no_offenses(<<~RUBY, gemfile)
        gemspec

        path ".." do
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when the path block does not point at sibling components" do
      write_component_gemspec(deps: %w[directory])

      expect_no_offenses(<<~RUBY, gemfile)
        gemspec

        path "components" do
          gem "nitro_react", require: nil
        end
      RUBY
    end
  end

  context "registers an offense" do
    it "when a gemspec dependency on a sibling is missing from the block, inserting it alphabetically" do
      write_component_gemspec(deps: %w[directory nitro_jobs nitro_react])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `nitro_jobs`.
          gem "directory", require: nil
          gem "nitro_react", require: nil
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path ".." do
          gem "directory", require: nil
          gem "nitro_jobs", require: nil
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when a missing development dependency sorts after every listed gem" do
      write_component_gemspec(deps: %w[directory], dev_deps: %w[nitro_linting])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `nitro_linting`.
          gem "directory", require: nil # comment stays here
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path ".." do
          gem "directory", require: nil # comment stays here
          gem "nitro_linting", require: nil
        end
      RUBY
    end

    it "when several dependencies are missing from the same place" do
      write_component_gemspec(deps: %w[nitro_react directory nitro_jobs])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`, `nitro_jobs`.
          gem "nitro_react", require: nil
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path ".." do
          gem "directory", require: nil
          gem "nitro_jobs", require: nil
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when missing dependencies go in different places" do
      write_component_gemspec(deps: %w[nitro_react directory nitro_jobs], dev_deps: %w[nitro_linting])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`, `nitro_linting`, `nitro_react`.
          gem "nitro_jobs", require: nil
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path ".." do
          gem "directory", require: nil
          gem "nitro_jobs", require: nil
          gem "nitro_linting", require: nil
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "when the block has no gems yet, inserting below its comment" do
      write_component_gemspec(deps: %w[directory])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`.
          # Dependencies on other components go here
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path ".." do
          # Dependencies on other components go here
          gem "directory", require: nil
        end
      RUBY
    end

    it "when the block is unsorted, inserting before the first gem that sorts after the missing one" do
      write_component_gemspec(deps: %w[directory nitro_jobs nitro_react])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path "../" do
        ^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `nitro_jobs`.
          gem "nitro_react", require: nil
          gem "directory", require: nil
        end
      RUBY

      expect_correction(<<~RUBY)
        gemspec

        path "../" do
          gem "nitro_jobs", require: nil
          gem "nitro_react", require: nil
          gem "directory", require: nil
        end
      RUBY
    end

    it "when a gem in the block is not declared in the gemspec" do
      write_component_gemspec(deps: %w[directory])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
          gem "directory", require: nil
          gem "nitro_react", require: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: `nitro_react` is in the `path ".."` block but not declared in `my_component.gemspec`. Declare it there, or remove it if this component doesn't use it directly.
          group :test do
            gem "nitro_jobs", require: nil
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: `nitro_jobs` is in the `path ".."` block but not declared in `my_component.gemspec`. Declare it there, or remove it if this component doesn't use it directly.
          end
        end
      RUBY

      expect_no_corrections
    end

    it "against the gemspec that gemspec names" do
      write_component_gemspec(deps: %w[directory])
      write_gemspec("my_component_extras", deps: %w[nitro_jobs], component: "my_component")

      expect_offense(<<~RUBY, gemfile)
        gemspec name: "my_component_extras"

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component_extras.gemspec`: `nitro_jobs`.
          gem "directory", require: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: `directory` is in the `path ".."` block but not declared in `my_component_extras.gemspec`. Declare it there, or remove it if this component doesn't use it directly.
        end
      RUBY
    end

    it "against the gemspec whose name gemspec names, whatever its file is called" do
      write_component_gemspec(deps: %w[directory])
      write_gemspec("my_component_extras", deps: %w[nitro_jobs], component: "my_component", file: "extras")

      expect_offense(<<~RUBY, gemfile)
        gemspec name: "my_component_extras"

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `extras.gemspec`: `nitro_jobs`.
          gem "directory", require: nil
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: `directory` is in the `path ".."` block but not declared in `extras.gemspec`. Declare it there, or remove it if this component doesn't use it directly.
        end
      RUBY
    end

    it "for missing gems only, when the gemspec declares a dependency whose name it can't read" do
      FileUtils.mkdir_p(File.dirname(gemfile))
      File.write(File.join(File.dirname(gemfile), "my_component.gemspec"), <<~RUBY)
        Gem::Specification.new do |s|
          s.name = "my_component"
          s.add_dependency "directory", "0.0.1"
          %w[nitro_jobs nitro_react].each { |dep| s.add_dependency dep, "0.0.1" }
        end
      RUBY

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`.
          gem "nitro_jobs", require: nil
          gem "nitro_react", require: nil
        end
      RUBY
    end

    it "without correcting a block written on one line" do
      write_component_gemspec(deps: %w[directory nitro_react])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path("..") { gem "nitro_react", require: nil }
        ^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`.
      RUBY

      expect_no_corrections
    end

    it "without correcting an empty block written on one line" do
      write_component_gemspec(deps: %w[directory])

      expect_offense(<<~RUBY, gemfile)
        gemspec

        path("..") {}
        ^^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`.
      RUBY

      expect_no_corrections
    end

    it "against the gemspec in the directory gemspec points at" do
      write_gemspec("my_component", deps: %w[directory], component: "my_component/engine")

      expect_offense(<<~RUBY, gemfile)
        gemspec path: "engine"

        path ".." do
        ^^^^^^^^^ Cobra/SyncedDependencyDeclaration: The `path ".."` block is missing components declared in `my_component.gemspec`: `directory`.
        end
      RUBY
    end
  end

  it "ignores dependencies that are not sibling components, and the component itself" do
    write_component_gemspec(deps: %w[rails my_component], dev_deps: %w[rspec])

    expect_no_offenses(<<~RUBY, gemfile)
      gemspec

      path ".." do
      end
    RUBY
  end

  describe "#external_dependency_checksum" do
    let(:component_dir) { File.join(components, "my_component") }
    let(:config) { RuboCop::Config.new({}, File.join(component_dir, ".rubocop.yml")) }

    def checksum
      described_class.new(config).external_dependency_checksum
    end

    def write_gemfile(source)
      File.write(File.join(component_dir, "Gemfile"), source)
    end

    it "changes when the gemspec the Gemfile loads changes" do
      write_component_gemspec(deps: %w[directory])
      write_gemfile("gemspec\n")
      before = checksum

      write_component_gemspec(deps: %w[directory nitro_jobs])

      expect(checksum).not_to eq(before)
    end

    it "changes when a gemspec loaded with gemspec path: changes" do
      write_gemspec("my_component", deps: %w[directory], component: "my_component/engine")
      write_gemfile(%(gemspec path: "engine"\n))
      before = checksum

      write_gemspec("my_component", deps: %w[directory nitro_jobs], component: "my_component/engine")

      expect(checksum).not_to eq(before)
    end

    it "changes when a sibling component is added" do
      write_component_gemspec(deps: %w[directory])
      write_gemfile("gemspec\n")
      before = checksum

      write_gemspec("new_component")

      expect(checksum).not_to eq(before)
    end

    it "still returns a checksum when there is no Gemfile" do
      write_component_gemspec(deps: %w[directory])

      expect(checksum).to match(/\A\h{64}\z/)
    end
  end
end
