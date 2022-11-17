# frozen_string_literal: true

require 'factory_bot'

module RubyTestHelpers
  # Helpers specifically for factory_bot
  module FactoryBotHelper
    def find_or_create(name, attributes = {}, &block)
      FactoryBot::Internal.factories.find(name).build_class.find_by(attributes, &block) ||
        FactoryBot.create(name, attributes, &block)
    end
  end
end

module FactoryBot
  class SyntaxRunner
    include RubyTestHelpers::FactoryBotHelper
  end
end

FactoryBot.use_parent_strategy = false
