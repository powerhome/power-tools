# frozen_string_literal: true

require_relative "spec_helper"
require "lumberaxe/railtie"

Combustion.initialize! :active_record, :action_controller

require "rspec/rails"
