# frozen_string_literal: true

module Audiences
  # @private
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
