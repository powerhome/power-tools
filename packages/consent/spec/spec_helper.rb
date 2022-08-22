# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'cancan'
require 'cancan/matchers'
require 'consent'
require 'date'

require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: File.join(__dir__, 'test.db')
)

class SomeModel < ActiveRecord::Base
  # id INTEGER PRIMARY KEY AUTOINCREMENT
  # name VARCHAR(255)
  # created_at DATETIME
end

RSpec.configure do |config|
  config.around(:example) do |example|
    ActiveRecord::Base.transaction(&example)
  end
end

Consent.default_views[:no_access] = Consent::View.new('', 'No Access')
Consent.load_subjects! [File.join(__dir__, 'permissions')]
