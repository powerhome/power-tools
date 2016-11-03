require 'consent/version'
require 'consent/subject'
require 'consent/view'
require 'consent/action'
require 'consent/dsl'
require 'consent/permission'
require 'consent/permissions'
require 'consent/ability' if defined?(CanCan)
require 'consent/railtie' if defined?(Rails)

module Consent
  FULL_ACCESS = %w(1 true).freeze

  def self.default_views
    @default_views ||= {}
  end

  def self.subjects
    @subjects ||= {}
  end

  def self.load_subjects!(paths)
    permission_files = paths.map { |dir| dir.join('*.rb') }
    Dir[*permission_files].each(&Kernel.method(:load))
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
