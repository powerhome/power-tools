# frozen_string_literal: true

require "attr_encrypted"
require "nitro_config"
require "simple_trail/engine"
require "simple_trail/entry_presenter"
require "simple_trail/recordable"
require "simple_trail/yaml_unsafe_coder"

module SimpleTrail
  def current_session_user_id(&block)
    
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
  def self.record!(object, activity, changes, user_id, note = nil, encrypted: false)
    klass = encrypted ? SimpleTrail::EncryptedHistory : SimpleTrail::History

    history = klass.for_source(object).create!(
      source_changes: changes,
      activity: activity,
      user_id: user_id,
      note: note
    )
    EntryPresenter.new(history)
  end

  # A collection of the history entries associated with the object
  #
  # @param object [#id] the object recording a history
  # @return [Array<NitroNotes::EntryPresenter>]
  def self.for(object, encrypted: false, in_natural_order: false)
    klass = encrypted ? SimpleTrail::EncryptedHistory : SimpleTrail::History

    history_collection = in_natural_order ? klass.for_source(object).in_natural_order : klass.for_source(object)
    history_collection.to_a.map do |history|
      SimpleTrail::EntryPresenter.new(history)
    end
  end
end
