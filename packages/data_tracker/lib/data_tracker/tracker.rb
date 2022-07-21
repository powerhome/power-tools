# frozen_string_literal: true

module DataTracker
  # :nodoc
  class Tracker
    def initialize(create:, update:, value:)
      @create = create
      @update = update
      @value = value

      super()
    end

    def apply(model)
      apply_relation(model, @create, :create) if @create
      apply_relation(model, @update, :update) if @update
    end

    def before_create(record)
      relation, _options = @create
      record.public_send("#{relation}=", @value.call)
    end

    def before_update(record)
      relation, _options = @update
      record.public_send("#{relation}=", @value.call)
    end

  private

    def apply_relation(model, relation_options, event)
      relation, options = relation_options

      return unless foreign_key_exist?(model, relation, **options)

      model.belongs_to relation, **options
      model.set_callback event, :before, self
    end

    def foreign_key_exist?(model, relation, foreign_key: nil, **)
      raise ArgumentError, "foreign_key is not set for #{relation}" unless foreign_key

      model.column_names.include?(foreign_key.to_s)
    end
  end
end
