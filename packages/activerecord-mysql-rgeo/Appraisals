# frozen_string_literal: true

appraise "rails-7-2" do
  gem "activerecord", "~> 7.2.0"
  # Active Record 7.2's test suite (rake regression) predates minitest 6.
  gem "minitest", "< 6"
end

appraise "rails-8-0" do
  gem "activerecord", "~> 8.0.0"
end

appraise "rails-8-1" do
  gem "activerecord", "~> 8.1.0"
end

appraise "rails-edge" do
  remove_gem "railties"

  git "https://github.com/rails/rails.git", branch: "main" do
    gem "activerecord"
    gem "activemodel"
    gem "activesupport"
    gem "railties"
  end
end
