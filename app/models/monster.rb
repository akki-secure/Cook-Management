class Monster < ApplicationRecord
  has_many :user_monsters, dependent: :destroy

  validates :name, presence: true
  validates :sprite_key, presence: true
  validates :unlock_min_level, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
end
