# frozen_string_literal: true

module CamelTrail
  module YAMLUnsafeCoder
  module_function

    # Loads the object from YAML.
    def load(payload)
      return unless payload

      if YAML.respond_to?(:unsafe_load)
        YAML.unsafe_load(payload)
      else
        YAML.load(payload) # rubocop:disable Security/YAMLLoad
      end
    end

    # Dumps the object to YAML.
    def dump(obj)
      YAML.dump obj
    end
  end
end
