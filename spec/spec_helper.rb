# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'cancan'
require 'cancan/matchers'
require 'consent'
require 'date'

SomeModel = Struct.new(:name, :created_at)

Consent.default_views[:no_access] = Consent::View.new('', 'No Access')
Consent.load_subjects! [File.join(__dir__, 'permissions')]
