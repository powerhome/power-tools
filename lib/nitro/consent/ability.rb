module Nitro
  module Consent
    class Ability
      include CanCan::Ability

      def initialize(permissions, *args)
        Nitro::Consent.permissions(permissions).each do |permission|
          conditions = permission.conditions(*args)
          can permission.action_key, permission.subject_key, conditions
        end
      end
    end
  end
end
