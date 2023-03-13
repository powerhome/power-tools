# frozen_string_literal: true

module SimpleTrail
  class History < ::SimpleTrail::ApplicationRecord
    serialize :source_changes, ::SimpleTrail::YAMLUnsafeCoder
    serialize :backtrace, Array

    default_scope { order("id DESC") }

    scope :for_source, ->(source_object) do
      where(source_id: source_object.id, source_type: source_object.class.to_s)
    end

    scope :in_natural_order, -> { reorder("id ASC") }

    before_create :set_backtrace

  private

    def set_backtrace
      self.backtrace = caller.select { |line| line.include?("/components") }
    end
  end
end
