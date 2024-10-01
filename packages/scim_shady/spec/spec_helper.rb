# frozen_string_literal: true

require "scim_shady"
require "pry"

FIXTURE_PATH = Pathname.new(__dir__).join("fixtures")
ScimShady.client = ScimShady::MockClient.new(FIXTURE_PATH, [
  {method: :Get, path: "Schemas", fixture: "Get-Schemas.json"},
  {method: :Get, path: "Groups", fixture: "Get-Groups.json"}
])

def fixture_json(fixture_path)
  JSON.parse(FIXTURE_PATH.join(fixture_path).read)
end

require_relative "resources/user"
require_relative "resources/group"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:example) do
    ScimShady.client.reset_mocks!
  end
end
