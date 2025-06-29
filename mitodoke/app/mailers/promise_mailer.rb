class PromiseMailer < ApplicationMailer
  def approve_email(promise, participant)
    @promise = promise
    @participant = participant
    @url = confirm_promise_url(@promise, token: @participant.token)

    mail(
      to: @participant.guest.email,
      subject: "【約束確認】承認をお願いします"
    )
  end

  def witnesse_email(promise, participant)
    @promise = promise
    @participant = participant
    @url = confirm_promise_url(@promise, token: @participant.token)

    mail(
      to: @participant.guest.email,
      subject: "【立会依頼】この約束に立ち会ってください"
    )
  end

  def completion_notice(promise, target)
    @promise = promise
    @target = target
    mail(
      to: @target.guest.email,
      subject: "約束が完了申請されました"
    )
  end

  def completion_notice_witnesse(promise, witnesse)
    @promise = promise
    @witnesse = witnesse
    mail(
      to: @witnesse.guest.email,
      subject: "完了した約束を確認してください"
    )
  end
end