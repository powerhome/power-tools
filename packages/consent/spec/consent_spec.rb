# frozen_string_literal: true

require "spec_helper"

describe Consent do
  describe ".define" do
    it "creates a new subject with the given key and label" do
      Consent.define(:lol_key, "My Label") {}

      expect(Consent.subjects.last.label).to eql "My Label"
      expect(Consent.subjects.last.key).to eql :lol_key
    end

    it "yields a in dsl context" do
      build_context = nil
      Consent.define(:lol_key, "My Label") do
        build_context = self
      end

      expect(build_context).to be_a(Consent::DSL)
      expect(build_context.subject).to be Consent.subjects.last
    end

    it "yields a in dsl context with defaults" do
      defaults = { views: [:my_view] }

      block = ->(*) {}
      expect(Consent::DSL).to receive(:build)
        .with(an_instance_of(Consent::Subject), defaults, &block)

      Consent.define :lol_key, "My Label", defaults: defaults, &block
    end

    it "allows a subject to have multiple action definitions" do
      Consent.define(:lol_key, "LOL at work") {}
      Consent.define(:lol_key, "LOL at home") {}

      keys = Consent.subjects.map(&:key)
      labels = Consent.subjects.map(&:label)

      expect(labels).to include "LOL at work", "LOL at home"
      expect(keys).to include :lol_key
    end
  end

  describe ".subjects_content" do
    it "returns concatenated contents of all permission files" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "file1.rb"), "# File 1\nConsent.define :test1")
      File.write(File.join(dir, "file2.rb"), "# File 2\nConsent.define :test2")

      content = Consent.subjects_content([dir])

      expect(content).to include("# File 1")
      expect(content).to include("# File 2")
      expect(content).to include("Consent.define :test1")
      expect(content).to include("Consent.define :test2")

      FileUtils.rm_rf(dir)
    end

    it "returns files in sorted order for deterministic results" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "z_last.rb"), "LAST")
      File.write(File.join(dir, "a_first.rb"), "FIRST")

      content = Consent.subjects_content([dir])

      expect(content.index("FIRST")).to be < content.index("LAST")

      FileUtils.rm_rf(dir)
    end
  end

  describe ".subjects_checksum" do
    it "returns MD5 hexdigest of permission file contents" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "test.rb"), "test content")

      checksum = Consent.subjects_checksum([dir])

      expect(checksum).to eq(Digest::MD5.hexdigest("test content"))

      FileUtils.rm_rf(dir)
    end

    it "returns same checksum for same content" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "test.rb"), "test content")

      checksum1 = Consent.subjects_checksum([dir])
      checksum2 = Consent.subjects_checksum([dir])

      expect(checksum1).to eq(checksum2)

      FileUtils.rm_rf(dir)
    end

    it "returns different checksum when content changes" do
      dir = Dir.mktmpdir
      File.write(File.join(dir, "test.rb"), "original content")
      checksum1 = Consent.subjects_checksum([dir])

      File.write(File.join(dir, "test.rb"), "modified content")
      checksum2 = Consent.subjects_checksum([dir])

      expect(checksum1).not_to eq(checksum2)

      FileUtils.rm_rf(dir)
    end
  end
end
