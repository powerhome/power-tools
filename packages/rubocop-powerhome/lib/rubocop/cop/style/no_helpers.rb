# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop does not allow helpers to be placed in an application. View objects,
      # specifically ViewComponent, create better Object Oriented design.
      # Global helper methods tightly couple templates.
      #
      class NoHelpers < RuboCop::Cop::Cop
        MSG = "Helpers create global view methods. Instead, use view objects to " \
              "encapsulate your display logic."

        def investigate(processed_source)
          return if processed_source.blank?
          return unless helper_path?

          add_offense(processed_source.ast, message: format(MSG))
        end

      private

        def helper_path?
          processed_source.file_path.include?("app/helpers/")
        end
      end
    end
  end
end
