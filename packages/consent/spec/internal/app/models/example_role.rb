# frozen_string_literal: true

class ExampleRole < ApplicationRecord
  include ::Consent::Authorizable
end
