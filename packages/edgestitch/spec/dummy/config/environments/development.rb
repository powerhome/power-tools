# frozen_string_literal: true

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.cache_store = :null_store
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
end
