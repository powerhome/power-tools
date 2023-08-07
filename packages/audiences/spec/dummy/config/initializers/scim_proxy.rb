# frozen_string_literal: true

require "audiences/scim_proxy"

Audiences::ScimProxy.config = {
  uri: "http://localhost:3002/api/scim/v2/",
  headers: {
    "Authorization" => "Bearer 123456789",
  },
  debug: $stdout,
}
