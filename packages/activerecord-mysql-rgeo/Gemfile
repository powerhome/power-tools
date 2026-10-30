# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Both drivers are development-only: the specs run against each of them.
gem "mysql2", "~> 0.5"
gem "trilogy", "~> 2.9"

gem "rake", "~> 13.0"
gem "rspec", "~> 3.13"
gem "rubocop-powerhome", path: "../rubocop-powerhome"

# Needed by Active Record's own test suite (rake regression).
gem "bcrypt"
gem "minitest-mock"
gem "msgpack"
gem "railties"
gem "sqlite3"
# Some tests use legacy zone names such as "EST", which newer OS tzdata
# packages leave out. Bundling the zone data makes the suite independent of it.
gem "tzinfo-data"
