# frozen_string_literal: true

require_relative "../regression/suite"

namespace :regression do
  %w[trilogy mysql2].each do |adapter|
    desc "Run Active Record's test suite against #{adapter} with the gem loaded"
    task adapter do
      Regression::Suite.new(adapter).run
    end
  end
end

desc "Run Active Record's test suite against every supported adapter"
task regression: %w[regression:trilogy regression:mysql2]
