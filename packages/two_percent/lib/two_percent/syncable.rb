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
    # Encapsulates type-specific SCIM synchronization logic
    #
    # This object replaces case statements and conditionals in the Syncable concern
    # by encapsulating all knowledge about User vs Group differences.
    #
    class Model
      attr_reader :scim_model_class, :scim_id_column, :resource_type, :options

      def initialize(scim_model_class:, scim_id_column:, resource_type:, **options)
        @scim_model_class = scim_model_class
        @scim_id_column = scim_id_column
        @resource_type = resource_type
        @options = options
      end

      # Setup association and validations on the domain model class
      #
      # @param domain_model_class [Class] The ActiveRecord model including Syncable
      def setup_association(domain_model_class)
        belongs_to_options = {
          class_name: scim_model_class.name,
          foreign_key: scim_id_column,
          primary_key: "scim_id",
          optional: true,
        }

        domain_model_class.belongs_to association_name, **belongs_to_options
        domain_model_class.validates scim_id_column, uniqueness: true, allow_nil: true
      end

      # Sync created event to domain model
      #
      # @param attributes [Hash] SCIM attributes from event
      # @param domain_model_class [Class] The domain model class
      # @return [ActiveRecord::Base] The synced record
      def sync_created(attributes, domain_model_class)
        sync_upsert(attributes, domain_model_class)
      end

      # Sync updated event to domain model
      #
      # @param attributes [Hash] SCIM attributes from event
      # @param domain_model_class [Class] The domain model class
      # @return [ActiveRecord::Base] The synced record
      def sync_updated(attributes, domain_model_class)
        sync_upsert(attributes, domain_model_class)
      end

      # Sync deleted event to domain model
      #
      # @param scim_id [String] SCIM ID of deleted resource
      # @param domain_model_class [Class] The domain model class
      # @return [ActiveRecord::Base, nil] The destroyed record
      def sync_deleted(scim_id, domain_model_class)
        record = domain_model_class.find_by(scim_id_column => scim_id)
        record&.destroy
      end

      # Sync domain model instance to SCIM
      #
      # @param domain_record [ActiveRecord::Base] Domain model instance
      # @param correlation_id [String, nil] Correlation ID for tracking
      # @return [ScimUser, ScimGroup] The synced SCIM record
      def sync_to_scim(domain_record, correlation_id:)
        scim_data = domain_record.map_domain_attributes_to_scim
        scim_record = domain_record.public_send(association_name)

        if scim_record
          # Update existing
          update_scim_record(scim_record, scim_data, correlation_id)
        else
          # Create new
          create_scim_record(domain_record, scim_data, correlation_id)
        end
      end

    private

      # Association name (:scim_user or :scim_group)
      def association_name
        @association_name ||= scim_model_class == TwoPercent::ScimUser ? :scim_user : :scim_group
      end

      # Shared logic for created/updated events
      def sync_upsert(attributes, domain_model_class)
        scim_id = attributes[:scim_id]
        return unless scim_id

        record = domain_model_class.find_or_initialize_by(scim_id_column => scim_id)
        mapped_attrs = domain_model_class.send(:map_scim_attributes_to_domain, attributes)
        record.assign_attributes(mapped_attrs)
        record.save! if record.changed?
        record
      end

      # Update existing SCIM record
      def update_scim_record(scim_record, scim_data, correlation_id)
        if scim_model_class == TwoPercent::ScimUser
          scim_record.update_from_scim!(scim_data, correlation_id: correlation_id)
        else
          scim_record.update_from_scim!(options[:resource_type] || "Groups", scim_data, correlation_id: correlation_id)
        end
        scim_record
      end

      # Create new SCIM record
      def create_scim_record(domain_record, scim_data, correlation_id)
        scim_record = if scim_model_class == TwoPercent::ScimUser
                        TwoPercent::ScimUser.upsert_from_scim(scim_data, correlation_id: correlation_id)
                      else
                        resource_type_value = options[:resource_type] || "Groups"
                        TwoPercent::ScimGroup.upsert_from_scim(resource_type_value, scim_data,
                                                               correlation_id: correlation_id)
                      end

        domain_record.update_column(scim_id_column, scim_record.scim_id)
        scim_record
      end
    end

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

        self.syncable_model = Model.new(
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
