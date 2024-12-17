# frozen_string_literal: true

class User < ScimShady::Base
  schema "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:extension:service:2.0:User"
end
