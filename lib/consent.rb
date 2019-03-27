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
    @subjects ||= []
  end

  def self.find_subjects(subject_key)
    @subjects.find_all do |subject|
      subject.key.eql?(subject_key)
    end
  end

  def self.find_action(subject_key, action_key)
    Consent.find_subjects(subject_key)
           .map(&:actions).flatten
           .find do |action|
             action.key.eql?(action_key)
           end
  end

  def self.find_view(subject_key, view_key)
    views = Consent.find_subjects(subject_key)
                   .map{|subject| subject.views}
                   .reduce({}, &:merge)
    views[view_key]
  end

  def self.load_subjects!(paths)
    permission_files = paths.map { |dir| dir.join('*.rb') }
    Dir[*permission_files].each(&Kernel.method(:load))
  end

  def self.define(key, label, options = {}, &block)
    defaults = options.fetch(:defaults, {})
    subjects << Subject.new(key, label).tap do |subject|
      DSL.build(subject, defaults, &block)
    end
  end

  def self.permissions(permissions)
    Permissions.new(permissions)
  end
end
