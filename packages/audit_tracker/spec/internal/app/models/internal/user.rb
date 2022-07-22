# frozen_string_literal: true

module Internal
  class User < ::Internal::ApplicationRecord
    belongs_to :department, class_name: "::Internal::Department"
  end
end
