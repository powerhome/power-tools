# frozen_string_literal: true

require "active_model"

module ScimShady
  # Client
  autoload :Client, "scim_shady/client"
  autoload :MockClient, "scim_shady/mock_client"

  # Base model
  autoload :Base, "scim_shady/base"
  autoload :Persistence, "scim_shady/persistence"
  autoload :ResourceQuery, "scim_shady/resource_query"
  autoload :SchemaAttributes, "scim_shady/schema_attributes"

  # Payloads
  autoload :PatchOp, "scim_shady/patch_op"
  autoload :ScimJson, "scim_shady/scim_json"

  # Others
  autoload :QueryBuilder, "scim_shady/query_builder"
  autoload :ListResponse, "scim_shady/list_response"
  autoload :Schema, "scim_shady/schema"
  autoload :VERSION, "scim_shady/version"

  # Errors
  autoload :Error, "scim_shady/errors"
  autoload :UnknownError, "scim_shady/errors"
  autoload :AuthenticationError, "scim_shady/errors"
  autoload :RequestError, "scim_shady/errors"
  autoload :UnknownSchema, "scim_shady/errors"
  autoload :ResourceNotFound, "scim_shady/errors"

  mattr_accessor :client
end
