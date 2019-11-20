# frozen_string_literal: true

module Consent
  # Defines a CanCan(Can)::Ability class based on a permissions hash
  class Ability
    include CanCan::Ability

    def initialize(permissions, *args)
      Consent.permissions(permissions).each do |permission|
        conditions = permission.conditions(*args)
        ocond = permission.object_conditions(*args)
        can permission.action_key, permission.subject_key, conditions, &ocond
      end
    end
  end
end
