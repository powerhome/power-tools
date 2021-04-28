# frozen_string_literal: true

require 'consent/version'
require 'consent/subject'
require 'consent/view'
require 'consent/action'
require 'consent/dsl'
require 'consent/permission'
require 'consent/ability' if defined?(CanCan)
require 'consent/railtie' if defined?(Rails)

# Consent makes defining permissions easier by providing a clean,
# concise DSL for authorization so that all abilities do not have
# to be in your `Ability` class.
module Consent
  ViewNotFound = Class.new(StandardError)

  # Default views available to every permission
  #
  # i.e.:
  #  Defining a view with no conditions:
  #  Consent.default_views[:all] = Consent::View.new(:all, "All")
  #
  # @return [Hash<Symbol,Consent::View>]
  def self.default_views
    @default_views ||= {}
  end

  # Subjects defined in Consent
  #
  # @return [Array<Consent::Subject>]
  def self.subjects
    @subjects ||= []
  end

  # Finds all subjects defined with the given key
  #
  # @return [Array<Consent::Subject>]
  def self.find_subjects(subject_key)
    subjects.find_all do |subject|
      subject.key.eql?(subject_key)
    end
  end

  # Finds an action within a subject context
  #
  # @return [Consent::Action,nil]
  def self.find_action(subject_key, action_key)
    find_subjects(subject_key)
      .flat_map(&:actions)
      .find do |action|
        action.key.eql?(action_key)
      end
  end

  # Finds a view within a subject context
  #
  # @return [Consent::View,nil]
  def self.find_view(subject_key, action_key, view_key)
    action = find_action(subject_key, action_key)
    action&.views[view_key] || raise(Consent::ViewNotFound)
  end

  # Loads all permission (ruby) files from the given directory
  # and using the given mechanism (default: :require)
  #
  # @param paths [Array<String,#to_s>] paths where the ruby files are located
  # @param mechanism [:require,:load] mechanism to load the files
  def self.load_subjects!(paths, mechanism = :require)
    permission_files = paths.map { |dir| File.join(dir, '*.rb') }
    Dir[*permission_files].each(&Kernel.method(mechanism))
  end

  # Defines a subject with the given key, label and options
  #
  # i.e:
  #   Consent.define :users, "User management" do
  #     view :department, "Same department only" do |user|
  #       { department_id: user.department_id }
  #     end
  #     action :read, "Can view users"
  #     action :update, "Can edit existing user", views: :department
  #   end
  def self.define(key, label, options = {}, &block)
    defaults = options.fetch(:defaults, {})
    subjects << Subject.new(key, label).tap do |subject|
      DSL.build(subject, defaults, &block)
    end
  end
end
