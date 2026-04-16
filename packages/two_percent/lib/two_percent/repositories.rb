# frozen_string_literal: true

module TwoPercent
  # Repository interfaces for SCIM resources
  # Apps implement these interfaces with their own models
  module Repositories
    autoload :UserRepository, "two_percent/repositories/user_repository"
    autoload :GroupRepository, "two_percent/repositories/group_repository"
  end
end
