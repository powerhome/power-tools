# frozen_string_literal: true

require "aether_observatory"

require "two_percent/version"
require "two_percent/configuration"
require "two_percent/domain"
require "two_percent/validates_user_groups_patch"
require "two_percent/bulk_processor"
require "two_percent/scim"
require "two_percent/syncable"
module TwoPercent
  # Custom exception for SCIM RFC 7643 read-only attribute violations
  class ReadOnlyAttributeError < StandardError; end

  # Logger used by TwoPercent. Defaults to Rails.logger
  def self.logger
    config.logger || Rails.logger
  end
end
