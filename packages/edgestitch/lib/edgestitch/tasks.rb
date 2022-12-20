# frozen_string_literal: true

require "rake/tasklib"

module Edgestitch
  # TODO: doc
  # @private
  module Tasks
    class << self
      include Rake::DSL

      def define_create(namespace = "db:stitch")
        desc "Create structure.sql for an app based on all loaded engines' structure-self.sql"
        task namespace => [:environment] do |_task, _args|
          ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
            ::Edgestitch::Renderer.to_file([*::Rails::Engine.subclasses, Rails.application], filename(db_config))
          end
        end

        enhance(namespace, "db:prepare", "db:structure:load", "db:schema:load")
      end

      def define_self(engine, namespace: "db:stitch", name: engine.engine_name)
        desc "Create structure-self.sql for an engine"
        task "#{namespace}:#{name}" => [:environment] do |_, _args|
          Rails.application.eager_load!
          engine&.eager_load!
          ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
            ::Edgestitch::Exporter.export(engine, ::Edgestitch::Mysql::Dump.new(db_config))
          end
        end

        enhance("#{namespace}:#{name}", "db:structure:dump", "app:db:structure:dump", "db:schema:dump",
                "app:db:schema:dump")
      end

    private

      def enhance(with, *tasks)
        tasks.each do |enhanced_task|
          Rake::Task[enhanced_task].enhance([with]) if Rake::Task.task_defined?(enhanced_task)
        end
      end

      def filename(db_config)
        if ::ActiveRecord::Tasks::DatabaseTasks.respond_to?(:schema_dump_path)
          ::ActiveRecord::Tasks::DatabaseTasks.schema_dump_path(db_config, :sql)
        else
          name = db_config.respond_to?(:name) ? db_config.name : db_config.spec_name
          ::ActiveRecord::Tasks::DatabaseTasks.dump_filename(name, :sql)
        end
      end
    end
  end
end
