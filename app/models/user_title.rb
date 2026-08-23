class UserTitle < ApplicationRecord
  belongs_to :user
  belongs_to :title

  validates :awarded_on, presence: true
end
