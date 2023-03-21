# frozen_string_literal: true

module CamelTrail
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
