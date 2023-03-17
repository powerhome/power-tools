# frozen_string_literal: true

require "attr_encrypted"
require "nitro_config"
require "simple_trail/engine"
require "simple_trail/entry_presenter"
require "simple_trail/recordable"
require "simple_trail/yaml_unsafe_coder"
require "simple_trail/config"

module SimpleTrail
  module_function
  mattr_accessor(:table_name_prefix) { "simple_trail_" }

  def self.config(...)
    Config.config(...)
  end

  # Records a history activity for the given object
  #
  # @param object [#id] the object recording a history
  # @param activity [Symbol] the activity that generated the history entry (i.e.: :created)
  # @param changes [Hash] an ActiveRecord changes hash (i.e.: { 'name' => ['old', 'new'] })
  # @param user_id [Integer] the id of the user triggered the history entry
  # @param note [String] a note that can be attached to a history
  # @param encrypted [Boolean] whether to encrypt or not the note
  # @return [SimpleTrail::EntryPresenter]

  # rubocop:disable Metrics/ParameterLists
  def record!(object, activity, changes, user_id, note = nil, encrypted: false)
    klass = encrypted ? SimpleTrail::EncryptedHistory : SimpleTrail::History

    history = klass.for_source(object).create!(
      source_changes: changes,
      activity: activity,
      user_id: user_id,
      note: note
    )
    EntryPresenter.new(history)
  end
  # rubocop:enable Metrics/ParameterLists

  # A collection of the history entries associated with the object
  #
  # @param object [#id] the object recording a history
  # @return [Array<SimpleTrail::EntryPresenter>]
  def for(object, encrypted: false, in_natural_order: false)
    klass = encrypted ? SimpleTrail::EncryptedHistory : SimpleTrail::History

    history_collection = in_natural_order ? klass.for_source(object).in_natural_order : klass.for_source(object)
    history_collection.to_a.map do |history|
      SimpleTrail::EntryPresenter.new(history)
    end
  end
end
