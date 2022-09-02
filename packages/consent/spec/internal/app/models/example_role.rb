# frozen_string_literal: true

class ExampleRole < ApplicationRecord
  include ::Consent::Authorizable

  belongs_to :example_department
end
