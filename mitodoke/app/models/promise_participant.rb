class PromiseParticipant < ApplicationRecord
  enum role: { offeror: 0, offeree: 1, witnesse: 2 }

  belongs_to :promise, optional: true
  #belongs_to :user, optional: true
  belongs_to :guest, optional: true

  validates :role, presence: true
  #validate :either_user_or_guest_present
  validates :token, presence: true, if: -> { guest_id.present? }

  before_validation :generate_token_if_guest

  private

  def generate_token_if_guest
    if guest_id.present? && token.blank?
      self.token = SecureRandom.urlsafe_base64(16)
    end
  end

  def either_user_or_guest_present
    if user_id.blank? && guest_id.blank?
      errors.add(:base, "user_id または guest_id のどちらかが必要です")
    end
  end

end
