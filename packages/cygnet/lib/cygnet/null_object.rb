# frozen_string_literal: true

module Cygnet
  # NullObject implements the widely-known NullObject pattern, where an instance
  # responds to any method called on it by returning another NullObject, allowing
  # arbitrary chaining of method calls without the risk of a NoMethodError.
  #
  # As an exception, NullObject can be cast to other types, taking a neutral
  # value of that type; it is cast to the empty string, 0, 0.0, the empty Array and Hash, etc.
  #
  # Additionally, it identifies positively as #nil? and #blank? for compatability
  # with common checks on "neutral" or "empty" values by imitating the behaviour of nil.
  class NullObject
    def method_missing(*_args, &_block)
      self
    end

    def respond_to_missing?(_method_name, _include_private = true)
      true
    end

    def nil?
      true
    end

    def blank?
      nil?
    end

    def !
      true
    end

    def to_s
      ''
    end

    def to_i
      0
    end

    def to_f
      0.0
    end

    def to_a
      []
    end

    def to_ary
      []
    end

    def to_h
      {}
    end

    def to_hash
      {}
    end

    def to_c
      Complex(0)
    end

    def to_r
      Rational(0)
    end
  end
end
