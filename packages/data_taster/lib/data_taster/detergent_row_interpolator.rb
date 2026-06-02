# frozen_string_literal: true

module DataTaster
  module DetergentRowInterpolator
    def self.replace_values(expression, row, client)
      result = expression.dup
      identifiers = row.keys.map(&:to_s).grep(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
      identifiers.sort_by! { |k| -k.size }
      identifiers.each do |key|
        next unless result.match?(/\b#{Regexp.escape(key)}\b/)

        result.gsub!(/\b#{Regexp.escape(key)}\b/, SqlLiteral.format(client, row[key]))
      end
      result
    end
  end
end
