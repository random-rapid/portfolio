class GuestsController < ApplicationController

  def new
    @guest = Guest.new
  end

  def create
    @guest = Guest.new(guest_params)
    if @guest.save
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def guest_params
    params.require(:guest).permit(:family_name, :given_name, :handle_name, :email)
  end
end
