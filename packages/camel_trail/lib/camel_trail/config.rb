# frozen_string_literal: true

module CamelTrail
  module Config
  module_function

    # CamelTrail Stores backtrace info in `camel_trail_histories`
    # It's config defaults to `Rails.backtrace_cleaner`
    # You can optionally set it to your customized backtrace cleaner
    # via `CamelTrail.config.backtrace_cleaner = MyBacktraceCleaner`
    mattr_accessor :backtrace_cleaner

    # Allows to set configurion for CamelTrail
    def config(&block)
      class_eval(&block)
    end

    # Optionally set `table_name_prefix` to customize default table name.
    # Defaults to `camel_trail_histories`
    def table_name_prefix(value)
      CamelTrail.table_name_prefix = value
    end

    # Sets `current_session_user_id` to include user info in `camel_trail_histories` table.
    def current_session_user_id(&block)
      @current_session_user_id = block if block
      @current_session_user_id
    end
  end
end
