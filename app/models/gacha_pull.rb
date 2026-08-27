class GachaPull < ApplicationRecord
  belongs_to :user
  belongs_to :monster, optional: true

  validates :cost, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
