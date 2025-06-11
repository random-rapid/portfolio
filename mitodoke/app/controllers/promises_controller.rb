class PromisesController < ApplicationController
  def new
    @promise = Promise.new
  end

  def create
    ActiveRecord::Base.transaction do
      promise = Promise.create!()

      [:offeror, :offeree, :winesse].each do |role|
        guest_data = params.require(role).permit(:name, :email)
        guest = Guest.find_or_create_by!(email: guest_data[:email]) do |g|
          g.name = guest_data[:name]
        end

        PromiseParticipant.create!(
          promise: promise,
          guest: guest,
          role: role
        )
      end

      # （例）ここで offeree にメール通知など可能
    end

    redirect_to promise_path(Promise.last), notice: "掲示板を作成しました"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_promise_path, alert: "作成に失敗しました: #{e.message}"
  end

  def show
    @promise = Promise.find(params[:id])
  end
end
