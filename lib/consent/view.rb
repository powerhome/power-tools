module Consent
  class View
    attr_reader :key, :label

    def initialize(key, label, instance = nil, collection = nil)
      @key = key
      @label = label
      @instance = instance
      @collection = collection
    end

    def conditions(*args)
      return @collection unless @collection.respond_to?(:call)
      @collection.call(*args)
    end

    def object_conditions(*args)
      return @instance unless @instance.respond_to?(:curry)
      @instance.curry[*args]
    end
  end
end
