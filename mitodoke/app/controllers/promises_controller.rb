class PromisesController < ApplicationController
  def new
    @promise = Promise.new
  end

  def create
    ActiveRecord::Base.transaction do
      @promise = Promise.create!({ progress: 0 })

      [:offeror, :offeree, :witnesse].each do |role|
        guest_data = params.require(role).permit(:family_name, :given_name, :email)#, :handle_name
        guest = Guest.find_or_create_by!(email: guest_data[:email]) do |g|
          g.family_name = guest_data[:family_name]
          g.given_name = guest_data[:given_name]
          #g.handle_name = guest_data[:handle_name]
          g.email = guest_data[:email]
        end

        PromiseParticipant.create!(
          promise: @promise,
          guest: guest,
          role: role,
          token: SecureRandom.hex(32)
        )
      end

    end
    offeror = @promise.promise_participants.find_by(role: 'offeror')
    redirect_to edit_promise_url(@promise, token: offeror.token), success: t('defaults.flash_message.created', item: Promise.model_name.human)
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
    token = params[:token]
    participant = @promise.promise_participants.find_by(token: token)

    if participant.nil? || participant.role != 'offeror'
      render plain: "権限がありません", status: :forbidden
      return
    end

    if @promise.progress >= 1
      redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
      return
    end
  end

  def update
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless participant&.role == 'offeror'
      render plain: "権限がありません", status: :forbidden
      return
    end

    if @promise.update(promise_params)
      @promise.update({ progress: 1 })
      offeree = @promise.promise_participants.find_by(role: 'offeree')
      PromiseMailer.approve_email(@promise, offeree).deliver_later
    else
      flash.now[:danger] = t('defaults.flash_message.not_updated', item: Promise.model_name.human)
      render :edit, status: :unprocessable_entity
    end

    if @promise.progress >= 1
      redirect_to confirm_promise_path(@promise, token: params[:token])
      return
    end
  end

  def confirm
    @promise = Promise.find(params[:id])
    @participant = @promise.promise_participants.find_by(token: params[:token])

    if @participant.nil?
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    @role = @participant.role
    @offeror = @promise.guest_offerors.first.decorate
    @offeree = @promise.guest_offerees.first.decorate
    @witnesse = @promise.guest_witnesses.first.decorate
  end

  def perform_approve
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    if participant&.role != 'offeree'
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    # すでに承認済みなら confirm に戻す
    if @promise.progress >= 2
      redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
      return
    end

    @promise.update!(progress: 2)
    witness = @promise.promise_participants.find_by(role: 'witnesse')
    PromiseMailer.witnesse_email(@promise, witness).deliver_later

    redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
  end

  def perform_witnesse
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    if participant&.role != 'witnesse'
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    # すでに立会済みなら confirm に戻す
    if @promise.progress >= 3
      redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
      return
    end

    @promise.update!(progress: 3)
    redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
  end

  private

  def promise_params
    params.require(:promise).permit(:content, :deadline, :penalty)
  end

  def notify_next_participant(promise)
    case promise.progress
    when 1
      guest = promise.guest_offerees.first
      participant = promise.promise_participants.find_by(token: params[:token])
      PromiseMailer.with(guest:, promise:, participant:).notify_offeree.deliver_later
    when 2
      guest = promise.guest_witnesses.first
      participant = promise.promise_participants.find_by(token: params[:token])
      PromiseMailer.with(guest:, promise:, participant:).notify_witnesse.deliver_later
    else
      Rails.logger.info "No further notifications required at progress=#{promise.progress}"
    end
  end
end
