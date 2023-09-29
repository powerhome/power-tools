# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'byebug'
require 'ostruct/sanitizer'

Dir['spec/fixtures/*.rb'].each do |f|
  require_relative "../#{f}"
end
