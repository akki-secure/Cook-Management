module Gamification
  # ガチャの消費コイン数・当選確率を一箇所に集約する定数モジュール。
  # バランス調整はここの数値を変えるだけで済むようにしてある。
  module GachaRules
    COST = 5
    WIN_RATE = 0.3
  end
end
