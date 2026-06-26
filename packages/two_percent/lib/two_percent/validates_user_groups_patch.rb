# frozen_string_literal: true

module TwoPercent
  # Validates PATCH operations against RFC 7643 read-only attributes
  #
  # Ensures User.groups attribute cannot be modified via PATCH operations,
  # as per RFC 7643 Section 4.1.2. Group memberships must be managed via
  # PATCH operations on the Group resource itself.
  module ValidatesUserGroupsPatch
    # Validate PATCH operations against RFC 7643 read-only attributes
    # @param resource_type [String] The SCIM resource type (e.g., "Users", "Groups")
    # @param patch_request [Hash] The PATCH request payload
    # @raise [TwoPercent::ReadOnlyAttributeError] if attempting to modify read-only User.groups
    def validate_patch_operations!(resource_type, patch_request)
      return unless resource_type == "Users"

      patch_request = patch_request.with_indifferent_access
      operations = patch_request[:Operations]
      return unless operations.is_a?(Array)

      operations.each { |operation| validate_operation_path!(operation.with_indifferent_access) }
    end

  private

    # Validate a single PATCH operation path for read-only attributes
    # @param operation [Hash] A single PATCH operation
    # @raise [TwoPercent::ReadOnlyAttributeError] if attempting to modify User.groups
    def validate_operation_path!(operation)
      path = operation[:path]
      value = operation[:value]

      # Check path-based operations (e.g., {op: "add", path: "groups", value: [...]})
      if path
        base_path = path.split(/[.\[]/).first
        raise_groups_read_only_error if base_path == "groups"
      end

      # Check pathless operations (e.g., {op: "replace", value: {active: true, groups: [...]}})
      return unless value.is_a?(Hash)

      value = value.with_indifferent_access
      raise_groups_read_only_error if value[:groups]
    end

    def raise_groups_read_only_error
      # RFC 7643 Section 4.1.2: User.groups is read-only
      # RFC 7644 Section 3.5.2: Return 400 with scimType="mutability"
      raise TwoPercent::ReadOnlyAttributeError,
            "Attribute 'groups' is read-only per SCIM RFC 7643. Manage group membership via PATCH /scim/Groups/{id}"
    end
  end
end
