# frozen_string_literal: true

module Sales
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
