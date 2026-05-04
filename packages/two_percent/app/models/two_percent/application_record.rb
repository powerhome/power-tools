# frozen_string_literal: true

module TwoPercent
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
