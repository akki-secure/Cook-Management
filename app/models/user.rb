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
  has_many :coin_events, dependent: :destroy
  has_many :gacha_pulls, dependent: :destroy
  has_many :user_monsters, dependent: :destroy
  has_many :monsters, -> { distinct }, through: :user_monsters
  has_many :user_titles, dependent: :destroy
  belongs_to :current_title, class_name: "Title", optional: true

  has_one_attached :avatar_image

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  HOUSE_LEVELS = [
    { min: 0,  max: 0,                key: "house_1_straw",          name: "藁の家" },
    { min: 1,  max: 2,                key: "house_2_wood",           name: "木の家" },
    { min: 3,  max: 6,                key: "house_2b_brick",         name: "レンガの家" },
    { min: 7,  max: 13,               key: "house_3_castle",         name: "城" },
    { min: 14, max: 29,               key: "house_4_palace",         name: "宮殿" },
    { min: 30, max: 59,               key: "house_5_skycastle",      name: "空飛ぶ城" },
    { min: 60, max: Float::INFINITY,  key: "house_6_diamond_palace", name: "ダイヤモンド宮殿" },
  ].freeze

  def house_info
    HOUSE_LEVELS.find { |h| current_streak_days.between?(h[:min], h[:max]) } || HOUSE_LEVELS.first
  end

  def next_house_info
    idx = HOUSE_LEVELS.index(house_info)
    HOUSE_LEVELS[idx + 1]
  end
end
