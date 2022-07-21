# frozen_string_literal: true

module Internal
  class ::Internal::ApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true
  end
end
