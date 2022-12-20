# frozen_string_literal: true

module Rabbet
  module Views
    module Helpers
      # Execute all registered view content injectors passing
      # a context hash with information that is currently provided
      # by the UIState#current_user.
      #
      # @param [Hash] context a hash with useful information that can be accessed by injectors.
      #
      def apply_injected_content(context:)
        Rabbet::Views.injectors.each do |section, injector|
          next if injector_is_nil?(section, injector)

          view_context = instance_exec(context, &injector)

          next if view_context.nil?

          # Avoid duplicate injector payloads
          next if content_for?(section) && @view_flow.get(section).include?(view_context)

          # Evaluates the content generator block within
          # the current view's context
          content_for section, view_context
        end
      end

      def injector_is_nil?(section, injector)
        section.nil? || injector.nil?
      end
    end
  end
end
