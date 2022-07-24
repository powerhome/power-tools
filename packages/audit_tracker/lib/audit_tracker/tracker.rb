# frozen_string_literal: true

module AuditTracker
  #
  # ::AuditTracker::Tracker represents the tracker and is responsible
  # for setting up the models to be tracked
  #
  # I.e.:
  #
  #   tracker = Tracker.new(
  #     create: [:created_by, class_name: "User", foreign_key: "created_by_id"]),
  #     update: [:updated_by, class_name: "User", foreign_key: "updated_by_id"]),
  #     value: -> { User.current }
  #   )
  #   tracker.apply(MyTrackedModel)
  #
  # After applying, if MyTrackedModel represents a table that contains the
  # necessary foreign keys, the relationships (`created_by` and `updated_by`)
  # and callbacks (before create / update) will be added to it.
  #
  # ::AuditTracker::Tracker is the core of AuditTracker, and a collection of trackers
  # is built into AuditTracker.trackers via AuditTracker.setup.
  #
  class Tracker
    def initialize(on:, value:)
      @on = on
      @value = value

      super()
    end

    def apply(model, overrides)
      @on.each do |event, relation, options|
        options = options.merge(overrides[relation] || {})
        apply_relation(model, relation, options, event)
      end
    end

  private

    def apply_relation(model, relation, options, event)
      return unless table_exists?(model)
      return unless foreign_key_exist?(model, relation, **options)

      value = options.delete(:value) || @value

      model.belongs_to relation, **options
      model.set_callback event, :before, Callback.new(value, relation, event)
    end

    def foreign_key_exist?(model, relation, foreign_key: nil, **)
      raise ArgumentError, "foreign_key is not set for #{relation}" unless foreign_key

      model.column_names.include?(foreign_key.to_s)
    end

    def table_exists?(model)
      model.table_exists?
    rescue
      false
    end

    # :nodoc:
    class Callback
      def initialize(value_fn, relation, event)
        @value = value_fn
        @relation = relation
        @event = event
      end

      def respond_to_missing?(method)
        method.to_s.eql?("before_#{@event}")
      end

      def method_missing(method, ...)
        if respond_to_missing?(method)
          call(...)
        else
          super
        end
      end

    private

      def call(record)
        association = record.association(@relation)
        return if record.attribute_changed?(association.reflection.foreign_key)

        association.writer(@value.call)
      end
    end
  end
end
