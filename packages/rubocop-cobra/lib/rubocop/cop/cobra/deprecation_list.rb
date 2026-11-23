# frozen_string_literal: true

module RuboCop
  module Cop
    module Cobra
      # The deprecated constants an application lists under
      # `Cobra/DeprecatedConstant`'s `Constants`, each mapped to its
      # replacement. A leading `::` on either side is ignored.
      #
      # Names match exactly, as Ruby does, unless `ignore_case:` is given.
      # Associations need that, because Rails camelizes their names with the
      # application's acronyms (`:api_keys` can become `APIKey`).
      class DeprecationList
        def initialize(constants)
          @replacements = constants.to_h.to_h do |deprecated, replacement|
            [deprecated.to_s.delete_prefix("::"), replacement.to_s.delete_prefix("::")]
          end
          @keys_by_downcase = @replacements.each_key.to_h { |key| [key.downcase, key] }
        end

        def replacement_for(deprecated)
          @replacements[deprecated]
        end

        def replacements
          @replacements.values
        end

        # The configured spelling of `name`, when it is deprecated.
        def deprecated(name, ignore_case: false)
          return @keys_by_downcase[name.downcase] if ignore_case

          name if @replacements.key?(name)
        end

        # A cheap check before resolving `name` through its namespaces: some
        # deprecated constant is `name` or ends in `::name`.
        def possibly_deprecated?(name, ignore_case: false)
          keys = ignore_case ? @keys_by_downcase.keys : @replacements.keys
          name = name.downcase if ignore_case
          keys.any? { |key| key == name || key.end_with?("::#{name}") }
        end
      end
    end
  end
end
