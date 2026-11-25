# frozen_string_literal: true

module RuboCop
  module Cop
    # Inserts `gem "<name>", require: nil` lines into a component Gemfile's
    # `path ".."` block, each before the first gem directly in the block whose
    # name sorts after it. With no such gem, the line goes after the block's last
    # gem, or just above the block's `end` when it has none, so it lands below
    # any comment in the block. Whole lines are inserted, so a comment on a
    # gem's line stays with that gem.
    #
    # A line is only inserted where it lands inside the block, so a block
    # written on one line, like `path("..") { gem "a", require: nil }`, is
    # left alone.
    class PathBlockInsertion
      def initialize(block, buffer)
        @block = block
        @buffer = buffer
      end

      # Names sharing an insertion point go in as one alphabetical insertion,
      # so their order doesn't depend on the order of the corrections.
      def insert(corrector, names)
        names.sort_by(&:downcase).group_by { |name| target_line(following_gem(name)) }.each do |line, group|
          next unless inside_block?(line)

          lines = group.map { |name| %(#{gem_indent}gem "#{name}", require: nil\n) }
          corrector.insert_before(line_range(line), lines.join)
        end
      end

    private

      def gems
        @gems ||= statements.select { |node| node.send_type? && node.method?(:gem) && node.first_argument&.str_type? }
      end

      def statements
        body = @block.body
        return [] if body.nil?

        body.begin_type? ? body.children : [body]
      end

      def following_gem(name)
        gems.find { |gem| gem.first_argument.value.downcase > name.downcase }
      end

      def target_line(following)
        return following.first_line if following

        gems.any? ? gems.last.last_line + 1 : @block.last_line
      end

      # Text inserted at the start of `line` is in the block only when the
      # line starts after the block opens and no later than its `end`.
      def inside_block?(line)
        return false if line > @buffer.last_line

        start = line_range(line).begin_pos
        start > @block.loc.begin.end_pos && start <= @block.loc.end.begin_pos
      end

      def gem_indent
        gems.any? ? indent(gems.first) : " " * (@block.loc.column + 2)
      end

      def line_range(line)
        @buffer.line_range(line)
      end

      def indent(node)
        " " * node.loc.column
      end
    end
  end
end
