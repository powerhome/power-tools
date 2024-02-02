# frozen_string_literal: true

module DepShield
  class Todos
    def initialize
      @todo_list = {}
    end

    def load(pathname)
      return unless File.exist?(pathname)

      list = YAML.load_file(pathname) || {}

      list.each do |feature_name, dep_todos|
        @todo_list[feature_name] ||= []
        @todo_list[feature_name] += dep_todos
      end
    end

    def allowed?(name, stack)
      @todo_list.fetch(name, []).any? do |allowed_file|
        stack.join("\n").include? allowed_file
      end
    end
  end
end
