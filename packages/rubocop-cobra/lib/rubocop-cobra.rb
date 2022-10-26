# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/cobra"

RuboCop::Cobra::Inject.defaults!

require_relative "rubocop/cop/cobra_cops"
