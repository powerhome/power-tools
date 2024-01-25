# frozen_string_literal: true

module DepShield
  class Todos
    def todo_list
      @todo_list ||= begin
        paths = Rails.root.glob("**/.deprecation_todo.yml")

        paths.each_with_object({}) do |path, list|
          YAML.load_file(path)&.each do |feature_name, dep_todos|
            list[feature_name] ||= []
            list[feature_name] += dep_todos
          end
        end
      end
    end

    def allowed?(name, stack)
      todo_list.fetch(name, []).any? do |allowed_file|
        stack.join("\n").include? allowed_file
      end
    end
  end
end
