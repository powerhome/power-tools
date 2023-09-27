require "ostruct"
require "ostruct/sanitizer/version"

module OStruct
  # Provides a series of sanitization rules to be applied on OpenStruct fields on
  # a Rails-ish fashion.
  #
  # @example
  #   class Person < OpenStruct
  #     include OStruct::Sanitizer
  #
  #     truncate :name, length: 20
  #     alphanumeric :name
  #     sanitize :middle_name do |value|
  #       # Perform a more complex sanitization process
  #     end
  #   end
  #
  module Sanitizer
    def self.included(base)
      unless base.ancestors.include? OpenStruct
        raise "#{self.name} can only be used within OpenStruct classes"
      end

      base.extend ClassMethods
    end

    # Initializes the OpenStruct applying any registered sanitization rules
    #
    def initialize(attrs = {})
      super nil
      attrs.each_pair do |field, value|
        self[field] = value
      end
    end

    # Creates a setter method for the corresponding field which applies any
    # existing sanitization rules
    #
    # @param [Symbol] method the missing method
    # @param [Array<Any>] args the method's arguments list
    #
    def method_missing(method, *args)
      # Give OpenStruct a chance to create getters and setters for the
      # corresponding field
      super method, *args

      if field = setter?(method)
        # override setter logic to apply any existing sanitization rules before
        # assigning the new value to the field
        override_setter_for(field) if sanitize?(field)
        # uses the newly created setter to set the field's value and apply any
        # existing sanitization rules
        send(method, args[0])
      end
    end

    # Set attribute's value via setter so that any existing sanitization rules
    # may be applied
    #
    # @param [Symbol|String] name the attribute's name
    # @param [Any] value the attribute's value
    #
    def []=(name, value)
      send("#{name}=", value)
    end

    private

    def setter?(method)
      method[/.*(?==\z)/m].to_s.to_sym
    end

    def override_setter_for(field)
      define_singleton_method("#{field}=") do |value|
        @table[field] = sanitize(field, value)
      end
    end

    def sanitize(field, value)
      return value if value.nil?
      self.class.sanitizers[field].reduce(value) do |current_value, sanitizer|
        sanitizer.call(current_value)
      end
    end

    def sanitize?(field)
      self.class.sanitizers.key? field
    end

    # Provides sanitization rules that can be declaratively applied to OpenStruct
    # fields, similar to hooks on Rails models.
    #
    module ClassMethods
      attr_accessor :sanitizers

      # Registers a sanitization block for a given field
      #
      # @param [Array<Symbol>] a list of field names to be sanitized
      # @param [#call] block sanitization block to be applied to the current value of each field and returns the new sanitized value
      #
      def sanitize(*fields, &block)
        @sanitizers ||= {}
        fields.each do |field|
          field_sanitizers = @sanitizers[field.to_sym] ||= []
          field_sanitizers << block
        end
      end

      # Truncates fields to a given length value
      #
      # @param [Array<Symbol>] a list of field names to be sanitized
      # @param [Integer] length the amount to truncate the field's value to
      # @param [Boolean] strip_whitespaces whether or not to strip whitespaces
      #
      def truncate(*fields, length:, strip_whitespaces: true)
        strip(*fields) if strip_whitespaces
        sanitize(*fields) { |value| value[0...length] }
        strip(*fields) if strip_whitespaces
      end

      # Remove any non-alphanumeric character from the field's value
      #
      # @param [Array<Symbol>] a list of field names to be sanitized
      #
      def alphanumeric(*fields)
        sanitize(*fields) { |value| value.gsub(/[^A-Za-z0-9\s]/, '') }
      end

      # Strips out leading and trailing spaces from the values of the given fields
      #
      # @param [Array<Symbol>] fields list of fields to be sanitized
      #
      def strip(*fields)
        sanitize(*fields) { |value| value.strip }
      end

      # Removes any non-digit character from the values of the given fields
      #
      # @param [Array<Symbol>] fields list of fields to be sanitized
      #
      def digits(*fields)
        sanitize(*fields) { |value| value.to_s.gsub(/[^0-9]/, '') }
      end
    end
  end
end
