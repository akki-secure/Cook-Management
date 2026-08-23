class Title < ApplicationRecord
  has_many :user_titles, dependent: :destroy
  has_many :users, foreign_key: :current_title_id, inverse_of: :current_title

  validates :name, presence: true
  validates :min_level, presence: true, uniqueness: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :rank, presence: true, uniqueness: true
end
