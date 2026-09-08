module Gamification
  # 対戦ミニゲームの結果を受け取り、ボス戦勝利時のみレインボーコインを付与する。
  # 対戦の演出・勝敗判定自体はクライアント(Godot/Web JS)側で完結させ、
  # このサービスは結果報告を受けて報酬を反映するだけの役割に留める。
  class BattleRewardService
    RAINBOW_COIN_REWARD = 1

    Result = Struct.new(:rainbow_coins_awarded, keyword_init: true)

    def self.call(user:, mode:, result:)
      new(user: user, mode: mode, result: result).call
    end

    def initialize(user:, mode:, result:)
      @user = user
      @mode = mode
      @result = result
    end

    def call
      return Result.new(rainbow_coins_awarded: 0) unless boss_win?

      user.update!(rainbow_coins: user.rainbow_coins + RAINBOW_COIN_REWARD)
      Result.new(rainbow_coins_awarded: RAINBOW_COIN_REWARD)
    end

    private

    attr_reader :user, :mode, :result

    def boss_win?
      mode == "boss" && result == "win"
    end
  end
end
