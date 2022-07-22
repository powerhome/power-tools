# frozen_string_literal: true

module DataTracker
  #
  # ::DataTracker::Tracker represents the tracker and is responsible
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
  # ::DataTracker::Tracker is the core of DataTracker, and a collection of trackers
  # is built into DataTracker.trackers via DataTracker.setup.
  #
  class Tracker
    def initialize(create:, update:, value:)
      @create = create
      @update = update
      @value = value

      super()
    end

    def apply(model, overrides)
      apply_relation(model, @create, :create, overrides) if @create
      apply_relation(model, @update, :update, overrides) if @update
    end

  private

    def apply_relation(model, relation_options, event, overrides)
      relation, relation_options = relation_options
      options = relation_options.merge(overrides.fetch(relation, {}))

      return unless foreign_key_exist?(model, relation, **options)

      value = options.delete(:value) || @value

      model.belongs_to relation, **options
      model.set_callback event, :before, Callback.new(value, relation)
    end

    def foreign_key_exist?(model, relation, foreign_key: nil, **)
      raise ArgumentError, "foreign_key is not set for #{relation}" unless foreign_key

      model.column_names.include?(foreign_key.to_s)
    end

    # :nodoc:
    class Callback
      def initialize(value_fn, relation)
        @value = value_fn
        @relation = relation
      end

      def before_create(record)
        record.public_send("#{@relation}=", @value.call)
      end

      def before_update(record)
        record.public_send("#{@relation}=", @value.call)
      end
    end
  end
end
