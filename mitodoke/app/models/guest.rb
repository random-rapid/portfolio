class Guest < ApplicationRecord
  validates :family_name, presence: true, length: { maximum: 255 }
  validates :given_name, presence: true, length: { maximum: 255 }
  #validates :handle_name, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_many :promise_participants, dependent: :destroy
  has_many :promises, through: :promise_participants
end
