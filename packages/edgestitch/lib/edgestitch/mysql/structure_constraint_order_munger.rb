# rubocop:disable all

module Edgestitch
  module Mysql
    class StructureConstraintOrderMunger
      class << self
        def munge(sql)
          start_idx = end_idx = nil
          lines = sql.split("\n")
          lines.each_with_index do |line, idx|
            if line =~ /^\s*CONSTRAINT\b/
              start_idx = idx if start_idx.nil?
            elsif start_idx
              end_idx = idx - 1
              unless end_idx == start_idx
                lines[start_idx..end_idx] = order_and_commafy(lines[start_idx..end_idx])
              end
              start_idx = end_idx = nil
            end
          end
          lines.join("\n")
        end

      private

        def ends_with_comma(s)
          s.rstrip.end_with?(",")
        end

        def decommafy(s)
          return s unless ends_with_comma(s.rstrip)
          "#{s.rstrip[0..-2]}\n"
        end

        def commafy(s)
          return s if ends_with_comma(s.rstrip)
          "#{s.rstrip},\n"
        end

        def order_and_commafy(lines)
          last_line_should_have_comma = ends_with_comma(lines[-1])
          lines.sort!
          # First lines.length-1 lines always need commas
          lines[0..-2].each_with_index do |line, idx|
            lines[idx] = commafy(line)
          end
          # Last line may or may not need comma
          if last_line_should_have_comma
            lines[-1] = commafy(lines[-1])
          else
            lines[-1] = decommafy(lines[-1])
          end
          lines
        end
      end
    end
  end
end
