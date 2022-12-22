# frozen_string_literal: true

module Rabbet
  # View injection
  module Views
    class << self
      def inject(section: :head, &block)
        injectors << [section, block]
      end

      def injectors
        @injectors ||= []
      end
    end
  end
end
