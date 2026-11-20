# frozen_string_literal: true

module ActiveRecord
  module MysqlRgeo
    # Names activerecord-mysql2rgeo-adapter gave the spatial type, which
    # application code may refer to. They still work, with a deprecation
    # warning. The upstream gem's other constants were internal.
    module DeprecatedConstants # :nodoc:
      TARGET = "ActiveRecord::MysqlRgeo::Type::Spatial"

      class << self
        def define
          define_proxy(ActiveRecord::Type, :Spatial)
          upstream = define_module(ConnectionAdapters, :Mysql2Rgeo)
          define_proxy(define_module(upstream, :OID), :Spatial)
        end

      private

        def define_proxy(namespace, name)
          return if namespace.const_defined?(name, false)

          old_name = "#{namespace.name}::#{name}"
          proxy = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(old_name, TARGET, MysqlRgeo.deprecator)
          namespace.const_set(name, proxy)
        end

        def define_module(namespace, name)
          return namespace.const_get(name, false) if namespace.const_defined?(name, false)

          namespace.const_set(name, Module.new)
        end
      end
    end
  end
end
