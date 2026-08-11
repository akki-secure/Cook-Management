class User < ApplicationRecord
  has_secure_password

  generates_token_for :password_reset, expires_in: 30.minutes do
    # パスワード変更時にsaltも変わるため、トークンは自動的に失効する
    password_salt&.last(10)
  end

  has_many :recipes, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :ratings, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
