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

    def db_config
      ActiveRecord::Base.configurations
                        .configs_for(env_name: Rails.env, name: "primary")
                        .configuration_hash
    end

    def logg(message)
      DataTaster.logger.debug { "[#{Time.current}] #{message}" }
    end
  end
end
