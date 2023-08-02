# frozen_string_literal: true

module Audiences
  class Context < ApplicationRecord
    belongs_to :owner, polymorphic: true

    def key
      Audiences.sign(owner)
    end
  end
end
