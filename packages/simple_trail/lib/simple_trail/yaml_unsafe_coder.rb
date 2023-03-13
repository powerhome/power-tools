# frozen_string_literal: true

module SimpleTrail
  module YAMLUnsafeCoder
  module_function

    def load(payload)
      return unless payload

      if YAML.respond_to?(:unsafe_load)
        YAML.unsafe_load(payload)
      else
        YAML.load(payload) # rubocop:disable Security/YAMLLoad
      end
    end

    def dump(obj)
      YAML.dump obj
    end
  end
end
