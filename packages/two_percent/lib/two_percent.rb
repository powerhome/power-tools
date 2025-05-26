# frozen_string_literal: true

require "aether_observatory"

require "two_percent/version"
require "two_percent/configuration"

module TwoPercent
  # Logger used by TwoPercent. Defaults to Rails.logger
  def self.logger
    config.logger || Rails.logger
  end
end
