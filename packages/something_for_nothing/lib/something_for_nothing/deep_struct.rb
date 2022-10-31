# frozen_string_literal: true

require 'ostruct'
require 'something_for_nothing/null_object'

module SomethingForNothing
  # Using a deep struct gives one a lot of built-in, easy benefits because it was
  # designed for developer happiness.
  #
  # A Deep Struct can be used like a hash, but with the added ability to call
  # the keys of the hash like methods, ie `SomethingForNothing::DeepStruct.new(foo: { bar: 'baz' }).foo.bar`
  #
  # It also uses the Null Object pattern so that any missing keys/methods called
  # will return a NullObject instead of errors.
  #
  # @example
  #   api_data = SomethingForNothing::DeepStruct.new(id: 10, name: "Frank", address: { street: "Orchid Avenue" })
  #   puts "The user's name is #{api_data.name}"
  #   puts "The user lives on #{api_data.address.street}"
  #   parents_address = api_data.parents.address.street
  #   puts "His parents live at #{!!parents_address ? parents_address : 'somewhere else'}"
  #
  # @see http://andreapavoni.com/blog/2013/4/create-recursive-openstruct-from-a-ruby-hash
  #
  class DeepStruct < OpenStruct
    def initialize(hash = nil)
      super
      @table = {}
      @hash_table = {}

      return unless hash

      hash.each do |k, v|
        @table[k.to_sym] = (v.is_a?(Hash) ? self.class.new(v) : v)
        @hash_table[k.to_sym] = v

        new_ostruct_member!(k)
      end
    end

    def to_h
      @hash_table
    end

    def method_missing(_symbol, *_args, &_block)
      SomethingForNothing::NullObject.new
    end

    def respond_to_missing?(_method_name, _include_private = true)
      true
    end
  end
end
