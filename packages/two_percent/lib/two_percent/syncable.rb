# frozen_string_literal: true

module TwoPercent
  # Syncable concern for bidirectional sync between domain models and SCIM data
  #
  # Usage:
  #   class User < ApplicationRecord
  #     include TwoPercent::Syncable
  #
  #     syncable_as :user, scim_id_column: :scim_id
  #   end
  #
  #   class Group < ApplicationRecord
  #     include TwoPercent::Syncable
  #
  #     syncable_as :group, scim_id_column: :scim_id
  #   end
  #
  # This provides:
  # - user.scim_user => linked ScimUser record
  # - user.sync_to_scim => push changes to SCIM
  # - User.sync_from_scim_event(event) => pull changes from SCIM events
  #
  module Syncable
    extend ActiveSupport::Concern

    included do
      class_attribute :syncable_model
    end

    class_methods do
      # Configure this model as syncable with SCIM
      #
      # @param type [Symbol] :user or :group
      # @param scim_id_column [Symbol] Column storing SCIM ID (default: :scim_id)
      # @param options [Hash] Additional configuration options
      # @option options [Boolean] :auto_sync Automatically sync changes (default: false)
      # @option options [String] :resource_type Resource type for groups (default: "Groups")
      #
      def syncable_as(type, scim_id_column: :scim_id, **options)
        scim_model_class = type == :user ? TwoPercent::ScimUser : TwoPercent::ScimGroup

        self.syncable_model = TwoPercent::Syncable::Model.new(
          scim_model_class: scim_model_class,
          scim_id_column: scim_id_column,
          resource_type: type,
          **options
        )

        syncable_model.setup_association(self)
        setup_callbacks if options[:auto_sync]
      end

      # Sync from a SCIM domain event
      #
      # Uses polymorphic dispatch - events know how to apply themselves
      #
      # @param event [TwoPercent::Domain::Events::Base] Domain event
      # @return [ActiveRecord::Base, nil] The affected record, if any
      #
      def sync_from_scim_event(event)
        event.apply_to_model(self)
      end

    private

      def setup_callbacks
        after_commit :sync_to_scim_async, on: %i[create update]
      end

      # Override this in your model to customize attribute mapping
      #
      # @param scim_attrs [Hash] SCIM attributes from event
      # @return [Hash] Attributes to assign to domain model
      def map_scim_attributes_to_domain(scim_attrs)
        # Default mapping - override in your model
        scim_attrs.slice(:external_id, :email, :display_name, :active)
      end
    end

    # Instance methods

    # Sync this record's data to SCIM
    #
    # @param correlation_id [String] Optional correlation ID for tracking
    # @return [ScimUser, ScimGroup] The synced SCIM record
    #
    def sync_to_scim(correlation_id: nil)
      self.class.syncable_model.sync_to_scim(self, correlation_id: correlation_id)
    end

    # Async version of sync_to_scim (requires ActiveJob)
    def sync_to_scim_async(correlation_id: nil)
      # TODO: Implement with ActiveJob
      # SyncToScimJob.perform_later(self.class.name, id, correlation_id)
      sync_to_scim(correlation_id: correlation_id)
    end

    # Refresh this record from SCIM data
    def refresh_from_scim
      model = self.class.syncable_model
      association_name = model.scim_model_class == TwoPercent::ScimUser ? :scim_user : :scim_group
      scim_record = public_send(association_name)

      return unless scim_record

      attrs = scim_record.to_domain_attributes
      assign_attributes(self.class.send(:map_scim_attributes_to_domain, attrs))
      save! if changed?
    end

    # Override this in your model to customize domain → SCIM mapping
    #
    # @return [Hash] SCIM-compliant resource hash
    def map_domain_attributes_to_scim
      model = self.class.syncable_model
      scim_id_value = send(model.scim_id_column)

      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:#{model.resource_type.to_s.capitalize}"],
        "id" => scim_id_value,
        "externalId" => try(:external_id) || "ext-#{id}",
        "displayName" => try(:display_name) || try(:name),
        "active" => try(:active),
      }.compact
    end
  end
end
