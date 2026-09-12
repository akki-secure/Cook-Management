module Gamification
  # ガチャの消費コイン数・当選確率を一箇所に集約する定数モジュール。
  # バランス調整はここの数値を変えるだけで済むようにしてある。
  module GachaRules
    COST = 1
    WIN_RATE = 0.5

    # user_monstersテーブルの肥大化を防ぐため、1ユーザーが保持できる
    # モンスター所持レコード数(重複所持も含む)の上限。
    MAX_OWNED_MONSTERS = 100

    # GachaPullService/SevenGachaPullServiceの両方から使う共通判定。
    def self.monster_limit_reached?(user)
      user.user_monsters.count >= MAX_OWNED_MONSTERS
    end
  end
end
