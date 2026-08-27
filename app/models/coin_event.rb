class CoinEvent < ApplicationRecord
  RECIPE_POST = "recipe_post"
  GACHA_PULL = "gacha_pull"
  SOURCE_TYPES = [ RECIPE_POST, GACHA_PULL ].freeze

  belongs_to :user

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :amount, presence: true, numericality: { only_integer: true, other_than: 0 }
  validates :occurred_on, presence: true
end
