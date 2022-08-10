# frozen_string_literal: true

class CampgroundsController < ApplicationController
  def create
    campground_params = params.require(:campground).permit(:name)
    campground = Campground.new(campground_params)

    if campground.save
      render json: campground, status: :created
    else
      render json: campground.errors, status: :unprocessable_entity
    end
  end
end
