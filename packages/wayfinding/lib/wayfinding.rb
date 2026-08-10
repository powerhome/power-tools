# frozen_string_literal: true

require "wayfinding/errors"
require "wayfinding/kind"
require "wayfinding/destination"
require "wayfinding/destination_list"
require "wayfinding/version"

# Cross-application URL resolution.
#
# Any component can link to any page without depending on the component that
# owns the route. Registered destinations are data, so this module's public
# surface never grows as destinations are added.
#
#   Wayfinding.register(
#     name: :home,
#     engine: -> { Projects::Engine },
#     helper: :home_path
#   )
#
#   Wayfinding.path_for(:home, home, current_tab: "Projects")
module Wayfinding
  class << self
    # Declare a named field contract. See Wayfinding::Kind.
    def define_kind(name, requires: [])
      kind = Kind.new(name: name, requires: requires)
      kinds[kind.name] = kind
    end

    def kinds = @kinds ||= {}

    # rubocop:disable Metrics/ParameterLists
    def register(name:, engine: nil, kind: nil, helper: nil, action: nil,
                 subject: nil, label: nil, description: nil, **attributes, &resolver)
      validate_resolution!(name, engine, helper, resolver)
      validate_ability!(name, action, subject)
      validate_kind!(name, kind, action: action, subject: subject, label: label,
                                 description: description, **attributes)

      destinations[name.to_sym] = Destination.new(
        name: name, engine: engine, kind: kind, helper: helper, action: action,
        subject: subject, label: label, description: description, resolver: resolver, **attributes
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def path_for(name, *, **params) = fetch(name).path(*, **params)

    def url_for(name, *, **params) = fetch(name).url(*, **params)

    def of_kind(name)
      name = name.to_sym
      DestinationList.new(destinations.each_value.select { |destination| destination.kind == name })
    end

    def fetch(name)
      destinations.fetch(name.to_sym) do
        raise UnregisteredDestination,
              "No destination registered for #{name.inspect}. Registered: #{registered_names.join(', ')}"
      end
    end

    def registered?(name) = destinations.key?(name.to_sym)

    def registered_names = destinations.keys.sort

    # Assert every expected destination is registered. Call at the end of an
    # initializer so a dropped registration fails the boot rather than rendering
    # a broken link.
    def verify!(expected)
      missing = Array(expected).map(&:to_sym) - registered_names
      return true if missing.empty?

      raise UnregisteredDestination, "Missing destination registrations: #{missing.join(', ')}"
    end

    # Snapshot the registry, yield, then restore it. Used by the RSpec helper so
    # a destination registered inside an example does not leak.
    def preserve!
      destinations_snapshot = destinations.dup
      kinds_snapshot = kinds.dup
      yield
    ensure
      @destinations = destinations_snapshot
      @kinds = kinds_snapshot
    end

    def reset!
      @destinations = {}
      @kinds = {}
    end

  private

    def destinations = @destinations ||= {}

    def validate_resolution!(name, engine, helper, resolver)
      raise InvalidDestination, "#{name.inspect} declares both `helper:` and a block; use one" if helper && resolver
      raise InvalidDestination, "#{name.inspect} declares neither `helper:` nor a block" unless helper || resolver
      raise InvalidDestination, "#{name.inspect} declares `helper:` without an `engine:`" if helper && engine.nil?
    end

    def validate_ability!(name, action, subject)
      return if action.nil? == subject.nil?

      raise InvalidDestination,
            "#{name.inspect} declares #{action ? '`action:` without `subject:`' : '`subject:` without `action:`'}; " \
            "an ability check needs both"
    end

    def validate_kind!(name, kind, **given)
      return if kind.nil?

      definition = kinds.fetch(kind.to_sym) do
        raise UnknownKind, "#{name.inspect} declares unknown kind #{kind.inspect}. Defined: #{kinds.keys.join(', ')}"
      end

      definition.validate!(name, given)
    end
  end
end
