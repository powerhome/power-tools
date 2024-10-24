# frozen_string_literal: true

module ScimShady
  module Persistence
    extend ActiveSupport::Concern

    def persisted?
      id.present?
    end

    def save(...)
      persisted? ? _patch_record : _create_record
    end

    def to_patch_op
      PatchOp.new(self)
    end

    def to_scim_json
      ScimJson.new(self)
    end

    private

    def _create_record
      ScimShady.client.post(path: resource_path, body: to_scim_json)
        .tap(&method(:assign_attributes))
        .tap { changes_applied }
    end

    def _patch_record
      ScimShady.client.patch(path: "#{resource_path}/#{id}", body: to_patch_op)
        .tap(&method(:assign_attributes))
        .tap { changes_applied }
    end
  end
end
