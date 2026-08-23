module Gamification
  # ログイン・継続的な活動記録（ストリーク）の判定とボーナスEXP付与を担う
  class StreakService
    def initialize(user)
      @user = user
    end

    # 同じ日に複数回呼ばれてもボーナスは1回のみ付与される
    def record_activity!(on: Date.current)
      return if user.last_activity_on == on

      new_streak = consecutive?(on) ? user.current_streak_days + 1 : 1
      user.update!(
        current_streak_days: new_streak,
        longest_streak_days: [ user.longest_streak_days, new_streak ].max,
        last_activity_on: on
      )
      grant_streak_bonus!(new_streak, on)
    end
    alias_method :record_login!, :record_activity!

    private

    attr_reader :user

    def consecutive?(on)
      user.last_activity_on == on - 1
    end

    def grant_streak_bonus!(streak_days, on)
      amount = [ ExpRules::LOGIN_STREAK_BASE_EXP + streak_days, ExpRules::LOGIN_STREAK_MAX_EXP ].min
      ExpGrantService.call(
        user: user, source_type: ExpEvent::LOGIN_STREAK, amount: amount, occurred_on: on
      )
    end
  end
end
