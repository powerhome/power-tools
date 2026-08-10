# frozen_string_literal: true

module Wayfinding
  # A named, engine-scoped URL resolver, optionally declaring a kind that
  # requires an ability check and display metadata.
  #
  # Fields Wayfinding gives behavior to: +action+ and +subject+ feed
  # +accessible_by+; +label+ and +description+ are resolved if callable, and
  # +description+ falls back to +label+. Every other field is stored inert and
  # read back through #[].
  class Destination
    BEHAVIORAL_FIELDS = %i[action subject label description].freeze

    attr_reader :name, :kind, :action, :attributes

    # rubocop:disable Metrics/ParameterLists
    def initialize(name:, engine: nil, kind: nil, helper: nil, action: nil,
                   subject: nil, label: nil, description: nil, resolver: nil, **attributes)
      @name = name.to_sym
      @engine = engine
      @kind = kind&.to_sym
      @helper = helper&.to_sym
      @action = action
      @subject = subject
      @label = label
      @description = description
      @resolver = resolver
      @attributes = attributes.freeze
      freeze
    end
    # rubocop:enable Metrics/ParameterLists

    def subject = resolve(@subject)

    def label = resolve(@label)

    def description = resolve(@description) || label

    # Inert attributes, plus the behavioral fields by name.
    def [](key)
      key = key.to_sym
      return public_send(key) if BEHAVIORAL_FIELDS.include?(key)

      attributes[key]
    end

    def path(*, **params)
      return resolver_result(*, **params) unless @helper

      url_helpers.public_send(@helper, *, **params)
    end

    def url(*, **params)
      raise Error, "#{name.inspect} was registered with a block; url is only derivable from `helper:`" unless @helper

      unless @helper.to_s.end_with?("_path")
        raise Error, "#{name.inspect} declares helper #{@helper.inspect}, which does not end in `_path`"
      end

      url_helpers.public_send(@helper.to_s.sub(/_path\z/, "_url"), *, **params)
    end

    def engine
      @engine.respond_to?(:call) ? @engine.call : @engine
    end

  private

    def resolver_result(*, **)
      return @resolver.call(*, **) unless @engine

      url_helpers.instance_exec(*, **, &@resolver)
    end

    def url_helpers
      engine.routes.url_helpers
    end

    def resolve(value)
      value.respond_to?(:call) ? value.call : value
    end
  end
end
