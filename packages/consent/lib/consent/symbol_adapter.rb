# frozen_string_literal: true

module CanYouReally
  # @private
  class SymbolAdapter < ::CanCan::ModelAdapters::AbstractAdapter
    def self.for_class?(subject)
      subject.is_a?(Symbol) || subject == Symbol
    end

    def self.override_conditions_hash_matching?(_subject, _conditions)
      true
    end

    def self.matches_conditions_hash?(_subject, _conditions)
      true
    end
  end
end
