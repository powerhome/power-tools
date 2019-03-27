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
        action && @views ? action.view_keys.sort.eql?(@views.sort) : !action.nil?
      end

      failure_message do |subject_key|
        action = Consent.find_action(subject_key, action_key)
        message = "expected %s (%s) to provide action %s" % [
          subject_key.to_s, subject.class, action_key
        ]

        if action && @views
          '%s with views %s, but actual views are %p' % [message, @views, action.view_keys]
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
        conditions ? view.try(:conditions, *@context).eql?(conditions) : !view.nil?
      end

      failure_message do |subject_key|
        view = Consent.find_view(subject_key, view_key)
        message = "expected %s (%s) to provide view %s with %p, but" % [
          subject_key.to_s, subject.class, view_key, conditions
        ]

        if view && conditions
          actual_conditions = view.conditions(*@context)
          '%s conditions are %p' % [message, actual_conditions]
        else
          actual_views = Consent.find_subjects(subject_key).map(&:views).map(&:keys).flatten
          '%s available views are %p' % [message, actual_views]
        end
      end
    end
  end
end
