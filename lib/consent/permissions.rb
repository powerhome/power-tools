# frozen_string_literal: true

module Consent
  class Permissions
    include Enumerable

    def initialize(permissions)
      @permissions = permissions
    end

    def each(&block)
      Consent.subjects.each do |subject|
        subject.actions.map do |action|
          map_permission subject, action
        end.compact.each(&block)
      end
    end

    private

    def map_permission(subject, action)
      subject_key = subject.permission_key
      actions = @permissions[subject_key] || @permissions[subject_key.to_s]
      view = actions && (actions[action.key] || actions[action.key.to_s])
      full(subject, action, view) || partial(subject, action, view)
    end

    def full(subject, action, view_key)
      return unless Consent::FULL_ACCESS.include?(view_key.to_s.strip)

      Permission.new(subject, action)
    end

    def partial(subject, action, view_key)
      view = subject.view_for(action, view_key.to_s.to_sym)
      return if view.nil?

      Permission.new(subject, action, view)
    end
  end
end
