# frozen_string_literal: true

module TwoPercent
  # Maps SCIM attributes to/from model attributes based on configuration
  class AttributeMapper
    def initialize(mapping, scim_data_column: :scim_data)
      @mapping = mapping
      @scim_data_column = scim_data_column
    end

    # Extract domain attributes from model (for events)
    # @param record [Object] The model instance
    # @return [Hash] Domain attributes
    def extract_domain_attributes(record)
      attributes = {}
      
      @mapping.each do |scim_attr, model_attr|
        value = extract_value(record, model_attr)
        attributes[scim_attr] = value if value.present?
      end
      
      # Add any unmapped SCIM attributes from scim_data if present
      if @scim_data_column && record.respond_to?(@scim_data_column)
        scim_data = record.public_send(@scim_data_column) || {}
        
        # Add photos and groups from scim_data if not in mapping
        attributes[:photos] ||= scim_data["photos"] if scim_data["photos"]
        attributes[:groups] ||= scim_data["groups"] if scim_data["groups"]
      end
      
      attributes.compact
    end

    # Build full SCIM representation from model (for HTTP responses)
    # @param record [Object] The model instance
    # @param resource_type [String] SCIM resource type
    # @return [Hash] Full SCIM resource
    def build_scim_representation(record, resource_type: "User")
      # Start with unmapped SCIM data if present
      if @scim_data_column && record.respond_to?(@scim_data_column)
        scim_data = record.public_send(@scim_data_column) || {}
        scim_hash = scim_data.dup
      else
        scim_hash = {}
      end
      
      # Override/add mapped attributes
      @mapping.each do |scim_attr, model_attr|
        value = extract_value(record, model_attr)
        next unless value.present?
        
        # Convert attribute name to SCIM format
        scim_key = scim_attribute_name(scim_attr)
        scim_hash[scim_key] = value
      end
      
      # Ensure id is present and correct
      if scim_hash["scimId"]
        scim_hash["id"] = scim_hash.delete("scimId")
      end
      
      # Add/update meta
      scim_hash["meta"] = build_meta(record, resource_type)
      
      scim_hash
    end

    # Update model attributes from SCIM data
    # @param record [Object] The model instance
    # @param scim_hash [Hash] SCIM data
    # @return [Hash] Attributes to update on the model
    def extract_model_attributes(scim_hash)
      attributes = {}
      unmapped_data = scim_hash.dup
      
      @mapping.each do |scim_attr, model_attr|
        # Try different key formats
        scim_key = scim_attr.to_s.camelize(:lower)
        value = scim_hash[scim_key] || scim_hash[scim_attr.to_s]
        
        if value.present? && model_attr.is_a?(Symbol)
          attributes[model_attr] = value
          unmapped_data.delete(scim_key)
          unmapped_data.delete(scim_attr.to_s)
        end
      end
      
      # Store unmapped data in scim_data column
      if @scim_data_column
        attributes[@scim_data_column] = unmapped_data
      end
      
      attributes
    end

    private

    def extract_value(record, model_attr)
      case model_attr
      when Symbol
        record.respond_to?(model_attr) ? record.public_send(model_attr) : nil
      when Proc
        model_attr.call(record)
      else
        nil
      end
    end

    def scim_attribute_name(attr)
      # Map common SCIM attribute names
      case attr
      when :scim_id then "id"
      when :external_id then "externalId"
      when :user_name then "userName"
      when :display_name then "displayName"
      when :resource_type then "resourceType"
      else
        attr.to_s.camelize(:lower)
      end
    end

    def build_meta(record, resource_type)
      meta = { "resourceType" => resource_type }
      
      if record.respond_to?(:created_at) && record.created_at
        meta["created"] = record.created_at.iso8601
      end
      
      if record.respond_to?(:updated_at) && record.updated_at
        meta["lastModified"] = record.updated_at.iso8601
      end
      
      meta
    end
  end
end
