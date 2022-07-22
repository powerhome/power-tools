# frozen_string_literal: true

module DataTracker
  # DataTracker DSL modules
  module DSL
    def self.build(&block)
      Setup.module_eval(&block)
    end

    # DataTracker::DSL::Setup is the DSL cotext of the block in DataTracker.setup
    #
    module Setup
    module_function

      def tracker(key, &block)
        ::DataTracker.trackers[key] = Tracking.build(&block)
      end
    end

    # DataTracker::DSL::Setup is the DSL cotext of the block in `DSL::Setup.tracker`
    #
    class Tracking
      def self.build(&block)
        tracker = new
        tracker.instance_eval(&block)
        tracker.tracker
      end

      def tracker
        ::DataTracker::Tracker.new(on: @on, value: @value)
      end

      def on(event, relation, **options)
        @on ||= []
        @on << [event, relation, options]
      end

      def update(relation, **options)
        on(:update, relation, **options)
      end
      
      def create(relation, **options)
        on(:create, relation, **options)
      end

      def value(&block)
        @value = block
      end
    end
  end
end
