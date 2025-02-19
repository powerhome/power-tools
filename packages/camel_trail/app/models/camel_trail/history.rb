# frozen_string_literal: true

module CamelTrail
  class History < ::CamelTrail::ApplicationRecord
    if Gem::Version.new(Rails.version) >= Gem::Version.new("7.1")
      serialize :source_changes, coder: CamelTrail::YAMLUnsafeCoder
      serialize :backtrace, type: Array
    else
      serialize :source_changes, CamelTrail::YAMLUnsafeCoder
      serialize :backtrace, Array
    end

    default_scope { order("id DESC") }

    scope :for_source, ->(source_object) do
      where(source_id: source_object.id, source_type: source_object.class.to_s)
    end

    scope :in_natural_order, -> { reorder("id ASC") }

    before_create :set_backtrace

  private

    def set_backtrace
      self.backtrace = CamelTrail::Config.backtrace_cleaner&.clean(caller) || caller
    end
  end
end
