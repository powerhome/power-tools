# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Trino
      # Behaviors that constrain AR's typical OLTP-shaped query patterns so they
      # don't accidentally hammer a Trino warehouse. Currently:
      #
      #   - `find_each` / `find_in_batches` raise: Trino's pagination model does
      #     not fit AR's batching cursor.
      #
      # Timeouts and slow-query notifications live in DatabaseStatements; they
      # apply regardless of caller pattern.
      module SafetyBelts
        BATCH_METHODS = %i[find_each find_in_batches in_batches].freeze

        BATCH_METHODS.each do |method|
          define_method(method) do |*_args, **_kwargs, &_block|
            raise Stagecoach::Error,
                  "stagecoach: #{method} is not supported on Trino-backed models. " \
                  "Use explicit LIMIT/OFFSET pagination or pluck aggregates instead."
          end
        end
      end
    end
  end
end
