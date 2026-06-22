# frozen_string_literal: true

module TwoPercent
  module Scim
    # SCIM RFC 7644 PATCH operation processor
    # Handles add, replace, remove operations on SCIM resources
    class PatchProcessor
      attr_reader :operations

      def initialize(patch_request)
        @operations = parse_operations(patch_request)
      end

      def apply_to_hash(scim_hash)
        result = scim_hash.deep_dup

        operations.each do |operation|
          case operation[:op].downcase
          when "add"
            apply_add(result, operation[:path], operation[:value])
          when "replace"
            apply_replace(result, operation[:path], operation[:value])
          when "remove"
            apply_remove(result, operation[:path], operation[:value])
          else
            raise ArgumentError, "Unknown PATCH operation: #{operation[:op]}"
          end
        end

        result
      end

    private

      def parse_operations(patch_request)
        ops = patch_request["Operations"] || patch_request[:Operations]
        raise ArgumentError, "PATCH request must contain 'Operations' array" unless ops.is_a?(Array)

        ops.flat_map do |op|
          derive_operation(op)
        end
      end

      def derive_operation(operation)
        # Handle nested value hashes by flattening to path notation
        case operation.fetch("value") { operation[:value] }
        when Hash
          operation.fetch("value") { operation[:value] }.flat_map do |key, value|
            path = [operation.fetch("path") { operation[:path] }, key].compact.join(".")
            derive_operation(
              "op" => operation.fetch("op") { operation[:op] },
              "path" => path,
              "value" => value
            )
          end
        else
          [{
            op: operation.fetch("op") { operation[:op] },
            path: operation.fetch("path") { operation[:path] },
            value: operation.fetch("value") { operation[:value] },
          }]
        end
      end

      def apply_add(hash, path, value)
        if path.nil? || path.empty?
          # No path means add to root
          hash.merge!(value) if value.is_a?(Hash)
        else
          keys = path.split(".")
          target = navigate_to_parent(hash, keys[0..-2])
          last_key = keys.last

          target[last_key] = if target[last_key].is_a?(Array)
                               (target[last_key] + [value]).flatten
                             else
                               value
                             end
        end
      end

      def apply_replace(hash, path, value)
        if path.nil? || path.empty?
          # No path means replace root attributes
          hash.merge!(value) if value.is_a?(Hash)
        else
          keys = path.split(".")
          target = navigate_to_parent(hash, keys[0..-2])
          target[keys.last] = value
        end
      end

      def apply_remove(hash, path, value = nil)
        return if path.nil? || path.empty?

        keys = path.split(".")
        target = navigate_to_parent(hash, keys[0..-2])
        last_key = keys.last

        # Special handling for members and groups arrays
        # Note: For User.groups, PATCH is rejected before reaching here (RFC 7643)
        if ["members", "groups"].include?(last_key)
          if value.nil? || (value.is_a?(Array) && value.empty?)
            # No value or empty array means remove all
            target[last_key] = []
          elsif target[last_key].is_a?(Array)
            # Value provided: remove specific items by filtering
            values_to_remove = Array(value).map { |v| v["value"] || v[:value] }.compact
            target[last_key] = target[last_key].reject do |item|
              item_value = item["value"] || item[:value]
              values_to_remove.include?(item_value)
            end
          end
        else
          target.delete(last_key)
        end
      end

      def navigate_to_parent(hash, keys)
        return hash if keys.empty?

        keys.reduce(hash) do |current, key|
          current[key] ||= {}
          current[key]
        end
      end
    end
  end
end
