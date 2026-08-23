class ExpEvent < ApplicationRecord
  RECIPE_POST = "recipe_post"
  LOGIN_STREAK = "login_streak"
  SOURCE_TYPES = [ RECIPE_POST, LOGIN_STREAK ].freeze

  belongs_to :user

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :occurred_on, presence: true
end
