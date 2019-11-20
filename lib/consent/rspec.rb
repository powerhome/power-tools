# frozen_string_literal: true

require 'consent'

module Consent
  module Rspec
    extend RSpec::Matchers::DSL

    matcher :consent_action do |action_key|
      chain :with_views do |*views|
        @views = views
      end

      match do |subject_key|
        action = Consent.find_action(subject_key, action_key)
        if action && @views
          values_match?(action.view_keys.sort, @views.sort)
        else
          !action.nil?
        end
      end

      failure_message do |subject_key|
        action = Consent.find_action(subject_key, action_key)
        message = format(
          'expected %<skey>s (%<sclass>s) to provide action %<action>s',
          skey: subject_key.to_s, sclass: subject.class, action: action_key
        )

        if action && @views
          format(
            '%<message>s with views %<views>s, but actual views are %<keys>p',
            message: message, views: @views, keys: action.view_keys
          )
        else
          message
        end
      end
    end

    matcher :consent_view do |view_key, conditions|
      chain :to do |*context|
        @context = context
      end

      match do |subject_key|
        view = Consent.find_view(subject_key, view_key)
        if conditions
          view&.conditions(*@context).eql?(conditions)
        else
          !view.nil?
        end
      end

      failure_message do |subject_key|
        view = Consent.find_view(subject_key, view_key)
        message = format(
          'expected %<skey>s (%<sclass>s) to provide view %<view>s with` \
          `%<conditions>p, but',
          skey: subject_key.to_s, sclass: subject.class,
          view: view_key, conditions: conditions
        )

        if view && conditions
          actual_conditions = view.conditions(*@context)
          format(
            '%<message>s conditions are %<conditions>p',
            message: message, conditions: actual_conditions
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
