class UserMonster < ApplicationRecord
  belongs_to :user
  belongs_to :monster

  validates :acquired_on, presence: true
end
