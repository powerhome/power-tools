# frozen_string_literal: true

module DataTaster
  # helpers used globally in DataTaster
  module Helper
    def sanitize_command(command, params = nil)
      sanitized_command = command.gsub(Shellwords.escape(ENV.fetch("DEV_DUMP_USER", nil)), "<username>")
                                 .gsub(Shellwords.escape(ENV.fetch("DEV_DUMP_PASSWORD", nil)), "<pwd>")
                                 .gsub(ENV.fetch("DEV_DUMP_PASSWORD", nil), "<pwd>")

      sanitized_command = sanitized_command.gsub(Shellwords.escape(params["password"]), "<pwd>") if params

      sanitized_command
    end

    def db_yml
      @db_yml ||= YAML.safe_load(ERB.new(Rails.root.join("config", "database.yml").read).result, aliases: true)
    end

    def db_config
      @db_config ||= db_yaml[Rails.env].key?("primary") ? db_yml[Rails.env]["primary"] : db_yml[Rails.env]
    end

    def logg(message)
      DataTaster.logger.debug { "[#{Time.current}] #{message}" }
    end
  end
end
