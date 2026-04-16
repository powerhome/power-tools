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
            apply_remove(result, operation[:path])
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
        case operation["value"] || operation[:value]
        when Hash
          (operation["value"] || operation[:value]).flat_map do |key, value|
            path = [operation["path"] || operation[:path], key].compact.join(".")
            derive_operation(
              "op" => operation["op"] || operation[:op],
              "path" => path,
              "value" => value
            )
          end
        else
          [{
            op: operation["op"] || operation[:op],
            path: operation["path"] || operation[:path],
            value: operation["value"] || operation[:value]
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
          
          if target[last_key].is_a?(Array)
            target[last_key] = (target[last_key] + [value]).flatten
          else
            target[last_key] = value
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

      def apply_remove(hash, path)
        return if path.nil? || path.empty?
        
        keys = path.split(".")
        target = navigate_to_parent(hash, keys[0..-2])
        target.delete(keys.last)
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
