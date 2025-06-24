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
end