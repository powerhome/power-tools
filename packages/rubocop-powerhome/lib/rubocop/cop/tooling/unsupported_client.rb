module RuboCop
  module Cop
    module Tooling
      class UnsupportedClient < RuboCop::Cop::Cop
        # TODO: Update this message to reference our internal wrapper and link to its documentation
        MSG = "Found an unsupported HTTP client. Please use `Net::HTTP` instead."

        HTTP_CLIENT_SEARCHES = {
          faraday: '$(def $_ _args `(send (const nil? :Faraday) ...))',
          # other clients
        }

        HTTP_CLIENT_SEARCHES.each { |client, definition| def_node_search(client, definition)  }

        def_node_search :reference_calls, '$(def $_ _args `(send nil? %1))'

        def on_class(node)
          summary(node).each_with_object(default_hash) do |(matcher, def_nodes), refs|
            def_nodes.each do |def_node|
              reference_calls(node, def_node.method_name) do |def_node_ref|
                refs[def_node.method_name][def_node_ref.method_name] = def_node_ref
              end

              add_offense(def_node, message: "Found #{matcher}!", severity: :fatal)
            end
          end
        end

        private

        def summary(node)
          HTTP_CLIENT_SEARCHES.keys.each_with_object(default_hash) do |matcher, summary|
            public_send(matcher, node) { |def_node| summary[matcher].push(def_node) }
          end
        end

        def default_hash
          Hash.new { |h, k| h[k] = [] }
        end
      end
    end
  end