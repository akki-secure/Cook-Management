module Gamification
  # レインボーコインを1枚消費して、通常ガチャの当落判定(GachaRules::WIN_RATE)を
  # 7回繰り返す。GachaPullServiceとは消費する通貨が違う(通常コインではなく
  # レインボーコイン)ため、gacha_pullsテーブルへの記録は行わず、
  # 当落結果の配列だけを返すシンプルな実装にしている。
  class SevenGachaPullService
    PULL_COUNT = 7
    COST = 1

    Result = Struct.new(:pulls, :error, keyword_init: true)

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return Result.new(pulls: [], error: :insufficient_rainbow_coins) if user.rainbow_coins < COST

      pulls = []
      ActiveRecord::Base.transaction do
        user.update!(rainbow_coins: user.rainbow_coins - COST)
        PULL_COUNT.times { pulls << roll_one }
      end

      Result.new(pulls: pulls, error: nil)
    end

    private

    attr_reader :user

    def roll_one
      hit = rand < GachaRules::WIN_RATE
      monster = nil

      if hit
        monster = Monster.order(Arel.sql("RAND()")).first
        UserMonster.create!(user: user, monster: monster, acquired_on: Date.current) if monster
      end

      { hit: hit, monster: monster }
    end
  end
end
