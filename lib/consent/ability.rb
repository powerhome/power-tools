# frozen_string_literal: true

module Consent
  # Defines a CanCan(Can)::Ability class based on a permissions hash
  class Ability
    include CanCan::Ability

    def initialize(permissions, *args)
      @context = *args
      Consent.permissions(permissions).each do |permission|
        consent permission: permission
      end
    end

    def consent(permission: nil, subject: nil, action: nil, view: nil)
      permission ||= Permission.new(subject, action, view)
      conditions = permission.conditions(*@context)
      ocond = permission.object_conditions(*@context)

      can permission.action_key, permission.subject_key, conditions, &ocond
    end
  end
end
