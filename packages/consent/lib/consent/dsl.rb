# frozen_string_literal: true

module Consent
  # @private
  class DSL # :nodoc:
    attr_reader :subject

    def initialize(subject, defaults)
      @subject = subject
      @defaults = defaults
    end

    def with_defaults(new_defaults, &block)
      DSL.build(@subject, @defaults.merge(new_defaults), &block)
    end

    # rubocop:disable Lint/UnusedBlockArgument, Security/Eval
    def eval_view(key, label, collection_conditions)
      view key, label do |user|
        eval(collection_conditions)
      end
    end
    # rubocop:enable Lint/UnusedBlockArgument, Security/Eval

    def view(key, label, instance = nil, collection = nil, &block)
      collection ||= block
      @subject.views[key] = View.new(key, label, instance, collection)
    end

    def action(key, label, options = {})
      @subject.actions << Action.new(@subject, key, label,
                                     @defaults.merge(options))
    end

    def self.build(subject, defaults = {}, &block)
      DSL.new(subject, defaults).instance_eval(&block)
    end
  end
end
