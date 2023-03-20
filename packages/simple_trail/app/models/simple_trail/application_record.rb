# frozen_string_literal: true

module SimpleTrail
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
