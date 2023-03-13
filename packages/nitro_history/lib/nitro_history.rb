# frozen_string_literal: true

require "directory"
require "nitro_attr_encrypted"
require "nitro_auth"
require "nitro_config"
require "nitro_graphql"
require "nitro_mysql"

require "nitro_history/engine"
require "nitro_history/entry_presenter"
require "nitro_history/graphql"
require "nitro_history/recordable"
require "nitro_history/yaml_unsafe_coder"

module NitroHistory
  # Records a history activity for the given object
  #
  # @param object [#id] the object recording a history
  # @param activity [Symbol] the activity that generated the history entry (i.e.: :created)
  # @param changes [Hash] an ActiveRecord changes hash (i.e.: { 'name' => ['old', 'new'] })
  # @param user_id [Integer] the id of the user triggered the history entry
  # @param note [String] a note that can be attached to a history
  # @param encrypted [Boolean] whether to encrypt or not the note
  # @return [NitroHistory::EntryPresenter]
  def self.record!(object, activity, changes, user_id, note = nil, encrypted: false)
    klass = encrypted ? NitroHistory::EncryptedHistory : NitroHistory::History

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
    klass = encrypted ? NitroHistory::EncryptedHistory : NitroHistory::History

    history_collection = in_natural_order ? klass.for_source(object).in_natural_order : klass.for_source(object)
    history_collection.to_a.map do |history|
      NitroHistory::EntryPresenter.new(history)
    end
  end
end
