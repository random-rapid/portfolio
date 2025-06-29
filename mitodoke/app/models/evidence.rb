class Evidence < ApplicationRecord
  belongs_to :promise
  has_one_attached :image
end
