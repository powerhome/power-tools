# frozen_string_literal: true

module DataTracker
  # :nodoc
  class Tracker
    def initialize(&block)
      instance_eval(&block)
      super
    end

    # , options)
    def apply(model)
      apply_create(model) # , options.fetch(:create, {}))
      apply_update(model) # , options.fetch(:update, {}))
    end

  # def before_create(record)
  #   relation, options = @create
  #   record.send("#{relation}=",  @value.call)
  # end

  # def before_update(record)
  #   relation, options = @create
  #   record[relation] = @value.call
  # end

  private

    # , overrides)
    def apply_create(model)
      return unless @create

      relation, options = @create

      model.belongs_to relation, **options # .merge(overrides)
      # model.before_create self
    end

    # , overrides)
    def apply_update(model)
      return unless @update

      relation, options = @update

      model.belongs_to relation, **options # .merge(overrides)
      # model.before_update self
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
end
