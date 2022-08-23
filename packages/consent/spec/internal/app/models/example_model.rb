# frozen_string_literal: true

class ExampleModel < ApplicationRecord
  belongs_to :example_role
  belongs_to :additional_role, class_name: "ExampleRole"
end
