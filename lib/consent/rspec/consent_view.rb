# frozen_string_literal: true

module Consent
  module Rspec
    # @private
    class ConsentView
      def initialize(view_key, conditions)
        @conditions = comparable_conditions(conditions) if conditions
        @view_key = view_key
      end

      def to(*context)
        @context = context
        self
      end

      def with_conditions(conditions)
        @conditions = comparable_conditions(conditions)
        self
      end

      def matches?(subject_key)
        @subject_key = subject_key
        @target = Consent.find_subjects(subject_key)
                         .map do |subject|
                           subject.views[@view_key]&.conditions(*@context)
                         end
                         .compact
                         .map(&method(:comparable_conditions))
        @target.include?(@conditions)
      end

      def failure_message
        failure_message_base 'to'
      end

      def failure_message_when_negated
        failure_message_base 'to not'
      end

      private

      def comparable_conditions(conditions)
        conditions
      end

      def failure_message_base(failure) # rubocop:disable Metrics/MethodLength
        message = format(
          'expected %<skey>s (%<sclass>s) %<fail>s provide view %<view>s with`\
          `%<conditions>p, but',
          skey: @subject_key.to_s, sclass: @subject_key.class,
          view: @view_key, conditions: @conditions, fail: failure
        )

        if @target.any?
          format(
            '%<message>s conditions are %<conditions>p',
            message: message, conditions: @target
          )
        else
          actual_views = Consent.find_subjects(subject_key)
                                .map(&:views)
                                .map(&:keys).flatten
          format(
            '%<message>s available views are %<views>p',
            message: message, views: actual_views
          )
        end
      end
    end
  end
end
