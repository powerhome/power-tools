# frozen_string_literal: true

require 'consent'
RSpec::Support.require_rspec_support 'fuzzy_matcher'

module Consent
  module Rspec
    # @private
    class ConsentAction
      def initialize(action_key)
        @action_key = action_key
      end

      def with_views(*views)
        @views = views
        self
      end

      def matches?(subject_key)
        @subject_key = subject_key
        @action = Consent.find_action(@subject_key, @action_key)
        if @action && @views
          RSpec::Support::FuzzyMatcher.values_match?(
            @action.views.keys.sort,
            @views.sort
          )
        else
          !@action.nil?
        end
      end

      def failure_message
        failure_message_base 'to'
      end

      def failure_message_when_negated
        failure_message_base 'to not'
      end

      private

      def failure_message_base(failure) # rubocop:disable Metrics/MethodLength
        message = format(
          'expected %<skey>s (%<sclass>s) %<failure> provide action %<action>s',
          skey: @subject_key.to_s, sclass: @subject_key.class,
          action: @action_key, failure: failure
        )

        if @action && @views
          format(
            '%<message>s with views %<views>s, but actual views are %<keys>p',
            message: message, views: @views, keys: @action.views.keys
          )
        else
          message
        end
      end
    end
  end
end
