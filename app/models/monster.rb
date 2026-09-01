class Monster < ApplicationRecord
  has_many :user_monsters, dependent: :destroy
  has_many :gacha_pulls, dependent: :nullify

  validates :name, presence: true
  validates :sprite_key, presence: true
end
