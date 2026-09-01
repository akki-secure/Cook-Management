module Gamification
  # コインを消費してガチャを1回回す。当たればモンスターを1体獲得する。
  class GachaPullService
    Result = Struct.new(:hit, :monster, :error, keyword_init: true)

    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      return Result.new(hit: false, monster: nil, error: :insufficient_coins) if user.coins < GachaRules::COST

      monster = nil
      hit = false

      ActiveRecord::Base.transaction do
        user.update!(coins: user.coins - GachaRules::COST)
        gacha_pull = GachaPull.create!(user: user, cost: GachaRules::COST, hit: false)
        CoinEvent.create!(
          user: user, source_type: CoinEvent::GACHA_PULL, source_id: gacha_pull.id,
          amount: -GachaRules::COST, occurred_on: Date.current
        )

        hit = rolled_hit?
        if hit
          monster = pick_monster
          UserMonster.create!(user: user, monster: monster, acquired_on: Date.current) if monster
        end
        gacha_pull.update!(hit: hit, monster: monster)
      end

      Result.new(hit: hit, monster: monster, error: nil)
    end

    private

    attr_reader :user

    # テストでスタブしやすいよう当落判定だけを独立したメソッドに切り出す
    def rolled_hit?
      rand < GachaRules::WIN_RATE
    end

    # レベルによる出現制限は設けず、登録されている全モンスターから均等にランダム抽選する
    def pick_monster
      Monster.order(Arel.sql("RAND()")).first
    end
  end
end
