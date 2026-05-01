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
      class_attribute :syncable_type
      class_attribute :syncable_scim_id_column
      class_attribute :syncable_options
    end

    class_methods do
      # Configure this model as syncable with SCIM
      #
      # @param type [Symbol] :user or :group
      # @param options [Hash] Configuration options
      # @option options [Symbol] :scim_id_column Column storing SCIM ID (default: :scim_id)
      # @option options [Boolean] :auto_sync Automatically sync changes (default: false)
      #
      def syncable_as(type, **options)
        self.syncable_type = type
        self.syncable_scim_id_column = options[:scim_id_column] || :scim_id
        self.syncable_options = options

        case type
        when :user
          setup_user_syncable
        when :group
          setup_group_syncable
        else
          raise ArgumentError, "Unsupported syncable type: #{type}. Use :user or :group"
        end

        setup_callbacks if options[:auto_sync]
      end

      # Sync from a SCIM domain event
      #
      # @param event [TwoPercent::Domain::Events::Base] Domain event
      #
      def sync_from_scim_event(event)
        case event
        when TwoPercent::Domain::Events::UserCreated, TwoPercent::Domain::Events::UserUpdated
          sync_user_from_event(event)
        when TwoPercent::Domain::Events::GroupCreated, TwoPercent::Domain::Events::GroupUpdated
          sync_group_from_event(event)
        when TwoPercent::Domain::Events::UserDeleted
          handle_user_deleted(event)
        when TwoPercent::Domain::Events::GroupDeleted
          handle_group_deleted(event)
        end
      end

    private

      def setup_user_syncable
        # Association to ScimUser
        belongs_to :scim_user,
                   class_name: "TwoPercent::ScimUser",
                   foreign_key: syncable_scim_id_column,
                   primary_key: "scim_id",
                   optional: true

        # Validation
        validates syncable_scim_id_column, uniqueness: true, allow_nil: true
      end

      def setup_group_syncable
        # Association to ScimGroup
        belongs_to :scim_group,
                   class_name: "TwoPercent::ScimGroup",
                   foreign_key: syncable_scim_id_column,
                   primary_key: "scim_id",
                   optional: true

        # Validation
        validates syncable_scim_id_column, uniqueness: true, allow_nil: true
      end

      def setup_callbacks
        after_commit :sync_to_scim_async, on: %i[create update]
      end

      def sync_user_from_event(event)
        attrs = event.user_attributes
        scim_id = attrs[:scim_id]

        return unless scim_id

        record = find_or_initialize_by(syncable_scim_id_column => scim_id)
        record.assign_attributes(map_scim_attributes_to_domain(attrs))
        record.save! if record.changed?
        record
      end

      def sync_group_from_event(event)
        attrs = event.group_attributes
        scim_id = attrs[:scim_id]

        return unless scim_id

        record = find_or_initialize_by(syncable_scim_id_column => scim_id)
        record.assign_attributes(map_scim_attributes_to_domain(attrs))
        record.save! if record.changed?
        record
      end

      def handle_user_deleted(event)
        record = find_by(syncable_scim_id_column => event.user_id)
        record&.destroy
      end

      def handle_group_deleted(event)
        record = find_by(syncable_scim_id_column => event.group_id)
        record&.destroy
      end

      # Override this in your model to customize attribute mapping
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
      case syncable_type
      when :user
        sync_user_to_scim(correlation_id: correlation_id)
      when :group
        sync_group_to_scim(correlation_id: correlation_id)
      end
    end

    # Async version of sync_to_scim (requires ActiveJob)
    def sync_to_scim_async(correlation_id: nil)
      # TODO: Implement with ActiveJob
      # SyncToScimJob.perform_later(self.class.name, id, correlation_id)
      sync_to_scim(correlation_id: correlation_id)
    end

    # Refresh this record from SCIM data
    def refresh_from_scim
      scim_record = case syncable_type
                    when :user
                      scim_user
                    when :group
                      scim_group
                    end

      return unless scim_record

      attrs = scim_record.to_domain_attributes
      assign_attributes(self.class.send(:map_scim_attributes_to_domain, attrs))
      save! if changed?
    end

    def sync_user_to_scim(correlation_id:)
      scim_data = map_domain_attributes_to_scim

      if scim_user
        # Update existing
        scim_user.update_from_scim!(scim_data, correlation_id: correlation_id)
        scim_user
      else
        # Create new
        scim_user = TwoPercent::ScimUser.upsert_from_scim(scim_data, correlation_id: correlation_id)
        update_column(syncable_scim_id_column, scim_user.scim_id)
        scim_user
      end
    end

    def sync_group_to_scim(correlation_id:)
      scim_data = map_domain_attributes_to_scim

      if scim_group
        # Update existing
        scim_group.update_from_scim!(scim_data, correlation_id: correlation_id)
        scim_group
      else
        # Create new (assuming Groups resource type)
        resource_type = syncable_options[:resource_type] || "Groups"
        scim_group = TwoPercent::ScimGroup.upsert_from_scim(resource_type, scim_data, correlation_id: correlation_id)
        update_column(syncable_scim_id_column, scim_group.scim_id)
        scim_group
      end
    end

    # Override this in your model to customize domain → SCIM mapping
    def map_domain_attributes_to_scim
      # Default SCIM structure
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:#{syncable_type.to_s.capitalize}"],
        "id" => send(syncable_scim_id_column),
        "externalId" => try(:external_id) || "ext-#{id}",
        "displayName" => try(:display_name) || try(:name),
        "active" => try(:active),
      }.compact
    end
  end
end
