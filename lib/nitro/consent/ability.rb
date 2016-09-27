module Nitro
  module Consent
    class Ability
      include CanCan::Ability

      def initialize(permissions, *args)
        Nitro::Consent.permissions(permissions).each do |permission|
          view = permission.view && permission.view.conditions(*args)
          can permission.action.key, permission.subject.key, view
        end
      end
    end
  end
end
