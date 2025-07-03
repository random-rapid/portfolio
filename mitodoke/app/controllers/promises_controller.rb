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
    @participant = @promise.promise_participants.find_by(token: params[:token])

    if @participant.nil?
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    @role = @participant.role
    @offeror = @promise.guest_offerors.first.decorate
    @offeree = @promise.guest_offerees.first.decorate
    @witnesse = @promise.guest_witnesses.first.decorate
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
    witnesse = @promise.promise_participants.find_by(role: 'witnesse')
    PromiseMailer.witnesse_email(@promise, witnesse).deliver_later

    redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
  end

  def perform_reject
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    if participant&.role != 'offeree'
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    # すでに承認または拒否済みなら confirm に戻す
    if @promise.progress >= 2
      redirect_to confirm_promise_path(@promise, token: params[:token]), status: :see_other
      return
    end

    @promise.update!(progress: 0)

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

  def complete_form
    @promise = Promise.find(params[:id])
    @evidence = Evidence.new
  end

  def submit_completion
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless %w[offeror offeree].include?(participant&.role)
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    # すでに完了申請済みならリダイレクト
    if @promise.progress == 4
      redirect_to promise_path(@promise, token: params[:token]), status: :see_other
      return
    end
    if params[:promise].present? && params[:promise][:evidence].present?
      @promise.evidence.attach(params[:promise][:evidence])
      @promise.update!(progress: 4, completed_by: participant.role)

      # メール送信
      target = @promise.promise_participants.find_by(role: participant.role == 'offeror' ? 'offeree' : 'offeror')
      PromiseMailer.completion_notice(@promise, target).deliver_later

      redirect_to promise_path(@promise, token: params[:token]), notice: "完了申請を受け付けました"
    else
      flash.now[:alert] = "画像を選択してください"
      render :complete_form, status: :unprocessable_entity
      return
    end
  end

  def review_completion
    @promise = Promise.find(params[:id])
    @participant = @promise.promise_participants.find_by(token: params[:token])

    if @participant.nil? || @participant.role == @promise.completed_by
      render plain: "不正なアクセスです", status: :forbidden and return
    end
  end

  def accept_completion
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    if participant.nil? || participant.role == @promise.completed_by
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    @promise.update!(progress: 5)

    witnesse = @promise.promise_participants.find_by(role: 'witnesse')
    PromiseMailer.completion_notice_witnesse(@promise, witnesse).deliver_later

    redirect_to promise_path(@promise, token: params[:token]), status: :see_other
  end

  def reject_completion
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    if participant.nil? || participant.role == @promise.completed_by
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    @promise.update!(progress: 3)
    redirect_to promise_path(@promise, token: params[:token]), status: :see_other
  end

  def completion_witnesse
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless participant&.role == 'witnesse'
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    Rails.logger.debug "DEBUG: 現在のprogressは#{@promise.progress}"

    # すでに立会済みならリダイレクト
    if @promise.progress >= 6
      Rails.logger.debug "すでにprogressが5以上のため、リダイレクトします"
      redirect_to promise_path(@promise, token: params[:token]), status: :see_other
      return
    end

    # 完了承認
    if @promise.update(progress: 6)
      Rails.logger.info "progressを6に更新しました"
      redirect_to promise_path(@promise, token: params[:token]), notice: "完了を確認しました", status: :see_other
    else
      Rails.logger.error "progressの更新に失敗しました: #{@promise.errors.full_messages}"
      render plain: "更新失敗", status: :internal_server_error
    end
  end

  def request_cancel
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless %w[offeror offeree].include?(participant&.role)
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    if @promise.progress >= 7
      redirect_to promise_path(@promise, token: params[:token]), status: :see_other and return
    end

    @promise.update!(progress: 7, cancel_requested_by: participant.role)

    # 相手方にメール通知
    target_role = participant.role == "offeror" ? "offeree" : "offeror"
    target = @promise.promise_participants.find_by(role: target_role)
    PromiseMailer.cancel_request_email(@promise, target).deliver_later

    redirect_to promise_path(@promise, token: params[:token]), notice: "解除申請を送信しました", status: :see_other
  end

  def approve_cancel
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless %w[offeror offeree].include?(participant&.role)
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    if @promise.progress != 7
      redirect_to promise_path(@promise, token: params[:token]), notice: "まだ解除申請はありません", status: :see_other
      return
    end

    # 申請者と逆のロールであることを確認
    if participant.role == @promise.cancel_requested_by
      render plain: "解除申請者は承認できません", status: :forbidden and return
    end

    @promise.update!(progress: 8)
    witnesse = @promise.promise_participants.find_by(role: 'witnesse')
    if witnesse.nil? || witnesse.guest.nil?
      Rails.logger.error "[PromiseMailer] witnesse or witnesse.guest is nil"
    else
      PromiseMailer.cancel_witnesse_email(@promise, witnesse).deliver_later
    end
    #PromiseMailer.cancel_witnesse_email(@promise, witnesse).deliver_later

    redirect_to promise_path(@promise, token: params[:token]), notice: "解除を承認しました", status: :see_other
  end

  def reject_cancel
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless %w[offeror offeree].include?(participant&.role)
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    # progressが7（解除申請中）でなければ無効
    if @promise.progress != 7
      redirect_to promise_path(@promise, token: params[:token]), notice: "解除申請はありません", status: :see_other
      return
    end

    # 申請者自身は拒否できない
    if participant.role == @promise.cancel_requested_by
      render plain: "申請者は拒否できません", status: :forbidden and return
    end

    # progress を 3 に戻す（立会完了状態に戻す）
    @promise.update!(progress: 3, cancel_requested_by: nil)

    redirect_to promise_path(@promise, token: params[:token]), notice: "解除申請を拒否しました", status: :see_other
  end

  # 立会（progress: 9）
  def complete_cancel
    @promise = Promise.find(params[:id])
    participant = @promise.promise_participants.find_by(token: params[:token])

    unless participant&.role == 'witnesse'
      render plain: "不正なアクセスです", status: :forbidden and return
    end

    if @promise.progress >= 9
      redirect_to promise_path(@promise, token: params[:token]), notice: "すでに解除は完了しています", status: :see_other
      return
    end

    @promise.update!(progress: 9)
    redirect_to promise_path(@promise, token: params[:token]), notice: "解除が完了しました", status: :see_other
  end

  private

  def promise_params
    params.require(:promise).permit(:content, :deadline, :penalty)
  end

  def evidence_params
    params.require(:evidence).permit(:image)
  end

end
