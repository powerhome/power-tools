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
  end
end
