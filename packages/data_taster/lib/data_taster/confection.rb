# frozen_string_literal: true

require "erb"
require "socket"
require "yaml"
require "data_taster/flavors"

module DataTaster
  # Ingests the list of data_taster_export_tables.yml files
  # and processes them through an erb template
  # returns a ruby hash of the data
  class Confection
    def assemble
      DataTaster.config.list.each_with_object(default_data) do |path, merged_list|
        merged_list.merge!(load_yml(path.to_s))
      end
    end

    def load_yml(filename)
      return {} unless File.exist?(filename)

      erb = ::ERB.new(File.read(filename))
      erb.filename = filename
      flavored_erb = erb.def_class(DataTaster::Flavors, "render()")
      erb_result = flavored_erb.new.render

      YAML.safe_load(erb_result.gsub(/((.|\n)*---)/, "\n---")) || {}
    end

  private

    def default_data
      {
        "schema_migrations" => "1 = 1",
      }
    end
  end
end
