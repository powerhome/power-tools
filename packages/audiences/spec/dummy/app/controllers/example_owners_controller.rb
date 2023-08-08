# frozen_string_literal: true

class ExampleOwnersController < ApplicationController
  before_action :set_example_owner, only: %i[show edit update destroy]

  # GET /example_owners
  def index
    @example_owners = ExampleOwner.all
  end

  # GET /example_owners/1
  def show; end

  # GET /example_owners/new
  def new
    @example_owner = ExampleOwner.new
  end

  # GET /example_owners/1/edit
  def edit; end

  # POST /example_owners
  def create
    @example_owner = ExampleOwner.new(example_owner_params)

    if @example_owner.save
      redirect_to @example_owner, notice: "Example owner was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /example_owners/1
  def update
    if @example_owner.update(example_owner_params)
      redirect_to @example_owner, notice: "Example owner was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /example_owners/1
  def destroy
    @example_owner.destroy
    redirect_to example_owners_url, notice: "Example owner was successfully destroyed.", status: :see_other
  end

private

  # Use callbacks to share common setup or constraints between actions.
  def set_example_owner
    @example_owner = ExampleOwner.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def example_owner_params
    params.require(:example_owner).permit(:name)
  end
end
