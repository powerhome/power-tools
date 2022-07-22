# frozen_string_literal: true

module Internal
  module ::Internal
    class ApplicationRecord < ::ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
