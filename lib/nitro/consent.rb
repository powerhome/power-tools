require 'nitro/consent/version'
require 'nitro/consent/subject'
require 'nitro/consent/view'
require 'nitro/consent/action'
require 'nitro/consent/dsl'
require 'nitro/consent/permission'
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
      subjects[key] = Subject.new(key, label).tap do |subject|
        DSL.build(subject, defaults, &block)
      end
    end

    def self.permissions(permissions)
      Permissions.load(permissions)
    end

    module Permissions
      def self.load(permissions)
        Nitro::Consent.subjects.values.map do |subject|
          subject.actions.map do |action|
            actions = permissions[subject.permission_key]
            next unless actions
            view_key = sanitize_view_key(actions[action.key])
            next if view_key == false
            Permission.new(subject, action, view_key)
          end
        end.flatten.compact
      end

      def self.sanitize_view_key(view)
        return false if ['0', ''].include?(view.to_s.strip)
        view
      end
    end
  end
end
