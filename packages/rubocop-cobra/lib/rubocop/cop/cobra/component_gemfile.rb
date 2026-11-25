# frozen_string_literal: true

module RuboCop
  module Cop
    # Node matchers for a component Gemfile's `path ".."` block, which declares
    # the sibling components the component depends on.
    #
    # The block counts when its path is the Gemfile's parent directory, written
    # as any of:
    #
    #   path ".." do
    #   path "../" do
    #   path "..", glob: "*/*.gemspec" do
    #   path File.expand_path("..", __dir__) do
    module ComponentGemfile
      extend NodePattern::Macros

      # @!method component_path_block?(node)
      def_node_matcher :component_path_block?, <<~PATTERN
        (block (send nil? :path #parent_directory? ...) (args) _)
      PATTERN

      # @!method gem_declarations(node)
      def_node_search :gem_declarations, "(send nil? :gem (str _) ...)"

    private

      # @!method parent_directory_from_dir?(node)
      def_node_matcher :parent_directory_from_dir?, <<~PATTERN
        (send (const {nil? cbase} :File) :expand_path (str #parent_directory_string?) (send nil? :__dir__))
      PATTERN

      def parent_directory?(node)
        (node.str_type? && parent_directory_string?(node.value)) || parent_directory_from_dir?(node)
      end

      def parent_directory_string?(path)
        %w[.. ../].include?(path)
      end
    end
  end
end
