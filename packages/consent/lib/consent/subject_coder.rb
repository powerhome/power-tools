# frozen_string_literal: true

module Consent
  # Coder for ability subjects
  module SubjectCoder
    module Model
      def self.included(base)
        if Gem::Version.new(Rails.version) > Gem::Version.new('7.0')
          base.serialize :subject, coder: Consent::SubjectCoder
        else
          base.serialize :subject, Consent::SubjectCoder
        end
      end
    end

  module_function

    # Loads the serialized key (snake case string) as a valid
    # permission subject (a constant or a symbol)
    #
    # @param key [String] snake case string representing a subject
    # @return [Module,Class,Symbol]
    def load(key)
      return nil unless key

      constant = key.camelize.safe_constantize
      constant.is_a?(Class) ? constant : key.to_sym
    end

    # Dumps a serialized key (snake case string) from a valid
    # permission subject (a constant or a symbol)
    #
    # @param key [Module,Class,Symbol] the subject key
    # @return [String]
    def dump(key)
      key.to_s.underscore
    end
  end
end
