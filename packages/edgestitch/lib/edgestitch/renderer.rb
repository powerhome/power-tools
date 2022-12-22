# frozen_string_literal: true

require "erb"

module Edgestitch
  # @private
  #
  # Renders a structure.sql file based on all given engine's structure-self.sql
  #
  class Renderer
    def initialize(engines)
      @engines = Set.new(engines)
    end

    def each_file(&block)
      @engines.map { |engine| engine.root.join("db", "structure-self.sql") }
              .filter(&:exist?)
              .uniq.each(&block)
    end

    def self.to_file(engines, file)
      File.write(file, new(engines).render)
    end
  end
end

erb = ERB.new(File.read(File.join(__dir__, "stitch.sql.erb")))
erb.def_method(Edgestitch::Renderer, "render()")
