# frozen_string_literal: true

require "rake/tasklib"

module Edgestitch
  # @private
  #
  # Define rake tasks to deal with edgestitch structurefiles:
  #
  #   db:stitch: creates a structure.sql out of loaded engines and application
  #              structure-self.sql
  #   db:stitch:<engine_name>: creates a structure-self.sql containing only the
  #                            engine's models and migrations
  #
  # In order to integrate well with rails, it also enhances tasks like db:structure:load,
  # db:prepare and others.
  #
  module Tasks
    class << self
      include Rake::DSL

      # Defines a task to stitch a structure.sql from loaded Engines.
      # This task is responsible for gathering all loaded engines and the current
      # application's structrure-self.sql and stitching them together into a
      # structure.sql.
      #
      # Rails enhancements will happen before each of these tasks:
      #
      # - db:prepare
      # - db:structure:load
      # - db:schema:load
      #
      # @param namespace [String] namespace where the task will run [default: db:stitch]
      # @param enhance_rails [Boolean] whether edgestitch should enhance the above tasks or not [default: true]
      # @return [Rake::Task]
      def define_stitch(namespace = "db:stitch", enhance_rails: true)
        enhance(namespace, "db:prepare", "db:structure:load", "db:schema:load") if enhance_rails
        desc "Create structure.sql for an app based on all loaded engines' structure-self.sql"
        task namespace => [:environment] do |_task, _args|
          ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
            ::Edgestitch::Stitcher.to_file(filename(db_config), *::Rails::Engine.subclasses, Rails.application)
          end
        end
      end

      # Defines a task to generate the structure-self.sql file from an engine.
      # This task is responsible for gathering all models owned by the engine and all
      # migrations defined within the engine and generate a structure-self.sql.
      #
      # Rails enhancements will happen before each of these tasks:
      #
      # - db:structure:dump
      # - db:schema:dump
      # - app:db:structure:dump
      # - app:db:schema:dump
      #
      # @param engine [Class<Rails::Engine>] target class of the task
      # @param namespace [String] the namespace where the target will be generated [default: db:stitch]
      # @param name [String] the name of the task within the given namespace [default: engine.engine_name]
      # @param enhance_rails [Boolean] whether edgestitch should enhance the above tasks or not [default: true]
      # @return [Rake::Task]
      def define_engine(engine, namespace: "db:stitch", name: engine.engine_name, enhance_rails: true)
        if enhance_rails
          enhance("#{namespace}:#{name}", "db:structure:dump", "app:db:structure:dump", "db:schema:dump",
                  "app:db:schema:dump")
        end

        desc "Create structure-self.sql for an engine"
        task "#{namespace}:#{name}" => [:environment] do |_, _args|
          Rails.application.eager_load!
          engine&.eager_load!
          ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).each do |db_config|
            ::Edgestitch::Exporter.export(engine, ::Edgestitch::Mysql::Dump.new(db_config))
          end
        end
      end

    private

      def enhance(with, *tasks)
        tasks.filter { |task| Rake::Task.task_defined?(task) }
             .each { |task| Rake::Task[task].enhance([with]) }
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
