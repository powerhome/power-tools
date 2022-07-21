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
      relation, options = @create
      record.public_send("#{relation}=", @value.call)
    end

    def before_update(record)
      relation, options = @update
      record.public_send("#{relation}=", @value.call)
    end

  private

    def apply_relation(model, relation_options, event)
      relation, options = relation_options

      model.belongs_to relation, **options
      model.set_callback event, :before, self
    end
  end
end
