class Promise < ApplicationRecord
  validates :content, presence: true, on: :update
  validates :deadline, presence: true, on: :update
  validates :penalty, presence: true, on: :update

  has_many :promise_participants, dependent: :destroy
  #has_many :users, through: :promise_participants
  has_many :guests, through: :promise_participants

  # 役割別の参加者取得
  has_many :user_offerors, -> { where(promise_participants: { role: 'offeror' }) },
           through: :promise_participants,
           source: :user

  has_many :guest_offerors, -> { where(promise_participants: { role: 'offeror' }) },
           through: :promise_participants,
           source: :guest

  has_many :user_offerees, -> { where(promise_participants: { role: 'offeree' }) },
           through: :promise_participants,
           source: :user

  has_many :guest_offerees, -> { where(promise_participants: { role: 'offeree' }) },
           through: :promise_participants,
           source: :guest

  has_many :user_witnesses, -> { where(promise_participants: { role: 'witnesse' }) },
           through: :promise_participants,
           source: :user

  has_many :guest_witnesses, -> { where(promise_participants: { role: 'witnesse' }) },
           through: :promise_participants,
           source: :guest

  # userかguestかに関わらずに呼びだす
  def call_offerors
    promise_participants.where(role: 'offeror')
  end

  def call_offerees
    promise_participants.where(role: 'offeree')
  end

  def call_winesses
    promise_participants.where(role: 'witnesse')
  end
end
