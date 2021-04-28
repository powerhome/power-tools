# frozen_string_literal: true

module Consent
  # Defines a CanCan(Can)::Ability class based on a permissions hash
  class Ability
    include CanCan::Ability

    def initialize(*args, apply_defaults: true)
      @context = *args
      apply_defaults! if apply_defaults
    end

    def consent!(subject: nil, action: nil, view: nil)
      view = case view
             when Consent::View
               view
             when Symbol
               Consent.find_view(subject, action, view)
             end

      can(
        action, subject,
        view&.conditions(*@context),
        &view&.object_conditions(*@context)
      )
    end

    def consent(**kwargs)
      consent!(**kwargs) rescue Consent::ViewNotFound
    end

    private

    def apply_defaults!
      Consent.subjects.each do |subject|
        subject.actions.each do |action|
          next unless action.default_view

          consent(
            subject: subject.key,
            action: action.key,
            view: action.default_view
          )
        end
      end
    end
  end
end
