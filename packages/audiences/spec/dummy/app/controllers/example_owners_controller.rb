# frozen_string_literal: true

class ExampleOwnersController < ApplicationController
  def show
    @example_owner = ExampleOwner.find(params[:id])
  end
end
