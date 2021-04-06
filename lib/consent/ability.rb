# frozen_string_literal: true

module Consent
  # Defines a CanCan(Can)::Ability class based on a permissions hash
  class Ability
    include CanCan::Ability

    def initialize(*args, apply_defaults: true)
      @context = *args
      apply_defaults! if apply_defaults
    end

    def consent(permission: nil, subject: nil, action: nil, view: nil)
      permission ||= Permission.new(subject, action, view)
      return unless permission.valid?

      can(
        permission.action_key, permission.subject_key,
        permission.conditions(*@context),
        &permission.object_conditions(*@context)
      )
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
