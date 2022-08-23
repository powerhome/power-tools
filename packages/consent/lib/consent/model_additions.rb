# frozen_string_literal: true

module Consent
  #
  # Accessible Through logic
  #
  # This module adds the accessible_through class method to a model.
  # It is included in the activerecord base classes by Consent::Engine.
  #
  # @see Consent::ModelAdditions::ClassMethods#accessible_through
  #
  module ModelAdditions
    module ClassMethods
      # Provides a scope within the model to find instances of the model that are accessible
      # by the given ability through a given relation in the main subject
      #
      # I.E.:
      #
      #      Given the following scenario
      #
      #      class User
      #        belongs_to :territory
      #      end
      #
      #      Consent.define User, "User permissions" do
      #        view :territory do |user|
      #          { territory: { id: user.territory_id } }
      #        end
      #        view :visible_territories do |user|
      #          { territory: { id: user.visible_territory_ids } }
      #        end
      #
      #        action :contact, views: %i[all no_access territory visible_territories]
      #      end
      #
      #    This would give you a list of territories that the given ability can
      #    contact their users:
      #
      #      > user = User.new(territory_id: 13, visible_territory_ids: [2, 3, 4])
      #      > ability = Consent::Ability.new(user.to_session_user)
      #      > ability.consent view: :territory, action: :contact, subject: User
      #      > Territory.accessible_through(ability, :contact, User).to_sql
      #      => SELECT * FROM territories WHERE id = 13
      #      > ability.consent view: :visible_territories, action: :contact, subject: User
      #      > Territory.accessible_through(ability, :contact, User).to_sql
      #      => SELECT * FROM territories WHERE ((id = 13) OR (id IN (2, 3, 4)))
      #
      # @param ability [Consent::Ability] ability performing the query
      # @param action_or_pair [Symbol,String] the name of the action or a subject/action pair
      # @param subject [Class,Symbol,nil] the subject in which the action is, when action_or_pair is just the action
      # @param relation [Symbol,Array<Symbol>] the relation or path to the relation
      #
      def accessible_through(ability, action_or_pair, subject = nil, relation: nil)
        relation ||= model_name.element.to_sym
        ability.relation_model_adapter(self, action_or_pair, subject, relation)
               .database_records
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end
  end
end
