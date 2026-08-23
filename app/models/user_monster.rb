class UserMonster < ApplicationRecord
  belongs_to :user
  belongs_to :monster

  validates :acquired_on, presence: true
  validates :acquired_year_month, presence: true, uniqueness: { scope: :user_id }
end
