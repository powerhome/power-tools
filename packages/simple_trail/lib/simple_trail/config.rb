  # frozen_string_literal: true

module SimpleTrail
  module Config
    module_function
    mattr_accessor :backtrace_cleaner

    def config(&block)
      class_eval(&block)
    end

    def table_name_prefix(value)
      SimpleTrail.table_name_prefix = value
    end

    def current_session_user_id(&block)
      @current_session_user_id = block if block
      @current_session_user_id
    end
  end
end
