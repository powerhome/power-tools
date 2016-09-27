require 'nitro/consent/version'
require 'nitro/consent/subject'
require 'nitro/consent/view'
require 'nitro/consent/action'
require 'nitro/consent/dsl'
require 'nitro/consent/permission'
require 'nitro/consent/permissions'
require 'nitro/consent/ability' if defined?(CanCan)
require 'nitro/consent/railtie' if defined?(Rails)

module Nitro
  module Consent
    FULL_ACCESS = %w(1 true).freeze

    def self.default_views
      @default_views ||= {}
    end

    def self.subjects
      @subjects ||= {}
    end

    def self.define(key, label, options = {}, &block)
      defaults = options.fetch(:defaults, {})
      subjects[key] = Subject.new(key, label).tap do |subject|
        DSL.build(subject, defaults, &block)
      end
    end

    def self.permissions(permissions)
      Permissions.new(permissions)
    end
  end
end
