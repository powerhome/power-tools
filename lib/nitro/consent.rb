require 'nitro/consent/version'
require 'nitro/consent/subject'
require 'nitro/consent/view'
require 'nitro/consent/action'
require 'nitro/consent/dsl'
require 'nitro/consent/ability' if defined?(CanCan)
require 'nitro/consent/railtie' if defined?(Rails)

module Nitro
  module Consent
    def self.default_views
      @default_views ||= {}
    end

    def self.subjects
      @subjects ||= {}
    end

    def self.define(key, label, options = {}, &block)
      defaults = options.fetch(:defaults, {})
      subjects[key] = Subject.new(key, label, options).tap do |subject|
        DSL.build(subject, defaults, &block)
      end
    end

    def self.permissions(permissions)
      Permissions.load(permissions)
    end

    Permission = Struct.new(:subject, :action, :view)

    module Permissions
      def self.load(permissions)
        Nitro::Consent.subjects.values.map do |subject|
          actions = permissions[subject.permission_key]
          next unless actions
          subject.actions.map do |action_key, action|
            view = actions[action_key]
            next if view.to_s.strip.empty? || view.to_s == '0'
            Permission.new(subject, action, subject.views[view.to_s.to_sym])
          end
        end.flatten.compact
      end
    end
  end
end
