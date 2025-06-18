class PromisesController < ApplicationController
  def new
    @promise = Promise.new
  end

  def create
    ActiveRecord::Base.transaction do
      @promise = Promise.create!()

      [:offeror, :offeree, :witnesse].each do |role|
        guest_data = params.require(role).permit(:family_name, :given_name, :handle_name, :email)
        guest = Guest.find_or_create_by!(email: guest_data[:email]) do |g|
          g.family_name = guest_data[:family_name]
          g.given_name = guest_data[:given_name]
          g.handle_name = guest_data[:handle_name]
          g.email = guest_data[:email]
        end

        PromiseParticipant.create!(
          promise: @promise,
          guest: guest,
          role: role,
          token: SecureRandom.hex(32)
        )
      end

      # （例）ここで offeree にメール通知など可能
    end

    redirect_to edit_promise_path(@promise), success: t('defaults.flash_message.created', item: Promise.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error e.record.errors.full_messages
    flash.now[:danger] = t('defaults.flash_message.not_created', item: Promise.model_name.human)
    render :new, status: :unprocessable_entity
  end

  def show
    @promise = Promise.find(params[:id])
  end

  def edit
    @promise = Promise.find(params[:id])
  end
#promise_path(@promise)
  def update
    @promise = Promise.find(params[:id])
    if @promise.update(promise_params)
      redirect_to root_path, success: t('defaults.flash_message.updated', item: Promise.model_name.human)
    else
      flash.now[:danger] = t('defaults.flash_message.not_updated', item: Promise.model_name.human)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def promise_params
    params.require(:promise).permit(:content, :deadline, :penalty)
  end


end
