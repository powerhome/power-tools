# frozen_string_literal: true

module NitroHistory
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
