# frozen_string_literal: true

module Wayfinding
  # A named field contract. Applications define kinds; Wayfinding only enforces them.
  #
  #   Wayfinding.define_kind(:report, requires: %i[label description action subject])
  #
  # +requires+ may name any field, whether or not Wayfinding gives it behavior.
  # Validation asserts presence only and never resolves callables, so a lazily
  # registered <tt>subject: -> { ProjectTask }</tt> passes without autoloading.
  class Kind
    attr_reader :name, :requires

    def initialize(name:, requires: [])
      @name = name.to_sym
      @requires = Array(requires).map(&:to_sym).freeze
      freeze
    end

    def validate!(destination_name, given)
      missing = requires.reject { |field| given.key?(field) && !given[field].nil? }
      return if missing.empty?

      raise InvalidDestination,
            "Destination #{destination_name.inspect} of kind #{name.inspect} " \
            "is missing required #{missing.length == 1 ? 'field' : 'fields'}: #{missing.join(', ')}"
    end
  end
end
