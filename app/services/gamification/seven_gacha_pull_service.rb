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
      limit_reached = false

      ActiveRecord::Base.transaction do
        # 同時に複数リクエストが来ても所持数の上限判定がすり抜けないよう、
        # ユーザー行をロックしてから判定・更新まで一貫して行う。
        user.lock!
        @owned_count = user.user_monsters.count

        if @owned_count >= GachaRules::MAX_OWNED_MONSTERS
          limit_reached = true
          raise ActiveRecord::Rollback
        end

        user.update!(rainbow_coins: user.rainbow_coins - COST)
        PULL_COUNT.times { pulls << roll_one }
      end

      return Result.new(pulls: [], error: :monster_limit_reached) if limit_reached

      Result.new(pulls: pulls, error: nil)
    end

    private

    attr_reader :user

    def roll_one
      hit = rand < GachaRules::WIN_RATE
      return { hit: false, monster: nil } unless hit

      monster = Monster.order(Arel.sql("RAND()")).first
      return { hit: false, monster: nil } unless monster

      # 7連の途中で上限に達した場合は、以降の当たりはレコードを追加せず
      # ハズレとして扱う(所持数の肥大化を防ぎつつ、表示と実データを一致させる)。
      if @owned_count >= GachaRules::MAX_OWNED_MONSTERS
        return { hit: false, monster: nil }
      end

      UserMonster.create!(user: user, monster: monster, acquired_on: Date.current)
      @owned_count += 1
      { hit: true, monster: monster }
    end
  end
end
