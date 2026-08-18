# frozen_string_literal: true

module Wayfinding
  # A named, engine-scoped URL resolver with arbitrary application metadata.
  # Metadata is stored without interpretation and read through #[]. Any field
  # can be resolved lazily through #value_for.
  class Destination
    attr_reader :name, :kind, :attributes

    # rubocop:disable Metrics/ParameterLists
    def initialize(name:, engine: nil, kind: nil, helper: nil, resolver: nil, **attributes)
      @name = name.to_sym
      @engine = engine
      @kind = kind&.to_sym
      @helper = helper&.to_sym
      @resolver = resolver
      @attributes = attributes.freeze
      freeze
    end
    # rubocop:enable Metrics/ParameterLists

    def action = self[:action]

    def subject = value_for(:subject)

    def [](key) = attributes[key.to_sym]

    def value_for(key) = resolve(self[key])

    def path(*, **params)
      return resolver_result(:path, *, **params) unless @helper

      url_helpers.public_send(@helper, *, **params)
    end

    def url(*, **params)
      return resolver_result(:url, *, **params) unless @helper

      unless @helper.to_s.end_with?("_path")
        raise Error, "#{name.inspect} declares helper #{@helper.inspect}, which does not end in `_path`"
      end

      url_helpers.public_send(@helper.to_s.sub(/_path\z/, "_url"), *, **params)
    end

    def engine
      @engine.is_a?(Proc) ? @engine.call : @engine
    end

  private

    def resolver_result(mode, *, **)
      return @resolver.call(*, **) unless @engine

      context = mode == :url ? UrlResolverContext.new(url_helpers) : url_helpers
      context.instance_exec(*, **, &@resolver)
    end

    def url_helpers
      engine.routes.url_helpers
    end

    def resolve(value)
      value.respond_to?(:call) ? value.call : value
    end
  end
end
