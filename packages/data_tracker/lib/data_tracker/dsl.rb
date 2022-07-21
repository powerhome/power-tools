# frozen_string_literal: true

# :nodoc
module DataTracker
  # :nodoc
  module DSL
    def self.build(&block)
      Setup.module_eval(&block)
    end

    # :nodoc
    module Setup
    module_function

      def tracker(key, &block)
        ::DataTracker.trackers[key] = Tracking.build(&block)
      end
    end

    # :nodoc
    class Tracking
      def self.build(&block)
        tracker = new
        tracker.instance_eval(&block)
        tracker.tracker
      end

      def tracker
        ::DataTracker::Tracker.new(
          create: @create,
          update: @update,
          value: @value
        )
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
end
