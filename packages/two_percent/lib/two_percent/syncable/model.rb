# frozen_string_literal: true

module TwoPercent
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
  end
end
