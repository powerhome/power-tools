# frozen_string_literal: true

require "aether_observatory"

require "two_percent/version"
require "two_percent/configuration"
require "two_percent/attribute_mapper"
require "two_percent/repositories"
require "two_percent/domain"
require "two_percent/bulk_processor"
require "two_percent/scim"

module TwoPercent
  # Logger used by TwoPercent. Defaults to Rails.logger
  def self.logger
    config.logger || Rails.logger
  end

  # Get user attribute mapper instance
  def self.user_mapper
    @user_mapper ||= AttributeMapper.new(
      config.user_attribute_mapping,
      scim_data_column: config.scim_data_column
    )
  end

  # Get group attribute mapper instance
  def self.group_mapper
    @group_mapper ||= AttributeMapper.new(
      config.group_attribute_mapping,
      scim_data_column: config.scim_data_column
    )
  end
end
