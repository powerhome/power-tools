# frozen_string_literal: true

module CamelTrail
  class EntryPresenter
    delegate :backtrace,
             :created_at,
             :activity,
             :source_type,
             :source_id,
             :source_changes,
             :user_id,
             :user,
             :note,
             :id,
             to: :history, prefix: false
    def initialize(history)
      @history = history
    end

    # Details the changes made to the source object.
    def describe_changes
      @history.source_changes.map do |field, change|
        describe_change(field, change)
      end
    end

  private

    attr_reader :history

    def describe_change(field, change)
      values = change.map { |value| format_value(field, value) }
      return unless values.any?

      from, to = *values
      to = "nothing" if to.blank?
      build_message(field, from, to)
    rescue
      "#{field}: #{from} - #{to}"
    end

    def format_value(field, val)
      val = val.strftime("%m/%d/%Y") if val.respond_to?(:strftime)
      val = val.map(&:humanize).join(", ") if val.is_a?(Array) && val.first.is_a?(String)
      val = number_to_currency(val, precision: 2) if numeric?(field, val)
      val
    end

    def build_message(field, from, to)
      if to == true
        "Selected #{field.to_s.titleize}"
      elsif from == true
        "Deselected #{field.to_s.titleize}"
      elsif from.present?
        "Changed #{field.to_s.titleize} from #{from} to #{to}"
      else
        "Changed #{field.to_s.titleize} to #{to}"
      end
    end

    def numeric?(field, val)
      field =~ /amount|price|cost|ceiling/i && val.respond_to?(:to_f) && val != ""
    end
  end
end
