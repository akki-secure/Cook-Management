class Monster < ApplicationRecord
  has_many :user_monsters, dependent: :destroy
  has_many :gacha_pulls, dependent: :nullify

  validates :name, presence: true
  validates :sprite_key, presence: true

  # 図鑑ページの種別タグ表示用。DBにカラムを追加せず、sprite_keyから決定する。
  TYPE_LABELS = {
    "egg_character.png" => "たまご",
    "milk.png" => "ドリンク",
    "pancake.png" => "スイーツ",
    "coffee_character.png" => "ドリンク",
    "ice.png" => "デザート",
    "spaghetti_character.png" => "めん類",
    "hamburger_character.png" => "がっつり",
    "lasagna_character.png" => "がっつり",
    "cofeezeri.png" => "デザート",
    "fried_rice_character.png" => "がっつり",
    "onion_character.png" => "やさい",
    "kakigori_character.png" => "なつのあじ"
  }.freeze

  # 図鑑ページのアニメーション種別。sprite_keyに応じて6種類を割り当てる。
  ANIMATION_CLASSES = %w[anim-bounce anim-sway anim-hop anim-jiggle anim-spinhop anim-float].freeze

  def type_label
    TYPE_LABELS.fetch(sprite_key, "モンスター")
  end

  def animation_class
    ANIMATION_CLASSES[sprite_key.bytes.sum % ANIMATION_CLASSES.size]
  end
end
