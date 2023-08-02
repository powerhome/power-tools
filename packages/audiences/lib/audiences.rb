# frozen_string_literal: true

require "audiences/version"

# Audiences system
# Audiences pushes notifications to your rails app when a
# SCIM backend updates a user, notifying matching audiences.
#
module Audiences
  GID_RESOURCE = "audiences"

module_function

  # Provides a key to load an audience context for the given owner.
  # An owner should implment GlobalID::Identification.
  #
  # @param owner [GlobalID::Identification] an owning model
  # @return [String] context key
  #
  def sign(owner)
    owner.to_sgid(for: GID_RESOURCE)
  end

  # Loads a context for the given context key
  #
  # @param token [String] a signed token (see #sign)
  # @return Audience::Context
  #
  def load(key)
    owner = GlobalID::Locator.locate_signed(key, for: GID_RESOURCE)
    ::Audiences::Context.where(owner: owner).first_or_create!.tap(&:readonly!)
  end
end
