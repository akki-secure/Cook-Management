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
  has_many :exp_events, dependent: :destroy
  has_many :user_monsters, dependent: :destroy
  has_many :monsters, through: :user_monsters
  has_many :user_titles, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  belongs_to :current_title, class_name: "Title", optional: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
