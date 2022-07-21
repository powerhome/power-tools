# frozen_string_literal: true

require_relative "data_tracker/version"

# :nodoc
module DataTracker
  # :nodoc
  class Error < StandardError; end

  def self.trackers
    @trackers ||= {}
  end

  def self.setup(&block)
    ::DataTracker::Builder.module_eval(&block)
  end

  def self.apply(model)
    @trackers.each do |_key, tracker|
      tracker.apply(model)
    end
  end

  # :nodoc
  class Tracker
    def initialize(&block)
      instance_eval(&block)
      super
    end

    def apply(model)
      apply_create(model)
      apply_update(model)
    end

  private

    def apply_create(model)
      return unless @create

      relation, options = @create

      model.belongs_to relation, **options
    end

    def apply_update(model)
      return unless @update

      relation, options = @update

      model.belongs_to relation, **options
    end

    def update(relation, **options)
      @update = [relation, options]
    end

    def create(relation, **options)
      @create = [relation, options]
    end

    def value(&block)
      @value = block
    end
  end

  # :nodoc
  module Builder
  module_function

    def tracker(key, &block)
      DataTracker.trackers[key] = Tracker.new(&block)
    end
  end
end
