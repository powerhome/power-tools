# frozen_string_literal: true

module Audiences
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true
  end
end
