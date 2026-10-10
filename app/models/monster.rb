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
    "kakigori_character.png" => "なつのあじ",
    "canape.png" => "おつまみ",
    "dragon_jelly.png" => "デザート",
    "ebi_chili.png" => "がっつり",
    "pizza_man.png" => "がっつり",
    "shish_kebab.png" => "がっつり",
    "somen.png" => "めん類"
  }.freeze

  # 図鑑ページのアニメーション種別。sprite_keyに応じて6種類を割り当てる。
  ANIMATION_CLASSES = %w[anim-bounce anim-sway anim-hop anim-jiggle anim-spinhop anim-float].freeze

  ATTACK_NAMES = {
    "charge"    => "ラッシュチャージ",
    "fire"      => "フレイムウェーブ",
    "ice"       => "アイスブレイカー",
    "beam"      => "ライトビーム",
    "lightning" => "サンダーボルト",
    "wind"      => "ブレードウィンド",
    "shockwave" => "ソニックブレイク"
  }.freeze

  ATTACK_ICONS = {
    "charge"    => "⚔️",
    "fire"      => "🔥",
    "ice"       => "❄️",
    "beam"      => "✨",
    "lightning" => "⚡",
    "wind"      => "🌪️",
    "shockwave" => "💥"
  }.freeze

  def type_label
    TYPE_LABELS.fetch(sprite_key, "モンスター")
  end

  def animation_class
    ANIMATION_CLASSES[sprite_key.bytes.sum % ANIMATION_CLASSES.size]
  end

  def attacks_array
    JSON.parse(attacks)
  rescue
    ["charge", "fire", "beam"]
  end

  def weakness_label
    weakness.present? ? "#{ATTACK_ICONS[weakness]} #{ATTACK_NAMES[weakness]}" : "なし"
  end

  def attacks_label
    attacks_array.map { |k| "#{ATTACK_ICONS[k]} #{ATTACK_NAMES[k]}" }.join(" / ")
  end
end
