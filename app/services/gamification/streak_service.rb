module Gamification
  # ログイン・継続的な活動記録（ストリーク）の判定とボーナスEXP付与を担う
  class StreakService
    def initialize(user)
      @user = user
    end

    # 同じ日に複数回呼ばれてもボーナスは1回のみ付与される
    def record_activity!(on: Date.current)
      return if user.last_activity_on == on

      if consecutive?(on)
        new_streak = user.current_streak_days + 1
        user.update!(
          current_streak_days: new_streak,
          longest_streak_days: [ user.longest_streak_days, new_streak ].max,
          last_activity_on: on
        )
        grant_streak_bonus!(new_streak, on)
        grant_freeze_if_milestone!(new_streak)
      elsif freeze_applicable?(on)
        # 1日スキップ救済: フリーズを消費して last_activity_on を昨日扱いにする
        user.update!(
          streak_freeze_count: user.streak_freeze_count - 1,
          last_activity_on: on - 1
        )
        record_activity!(on: on)
      else
        user.update!(current_streak_days: 1, last_activity_on: on)
        grant_streak_bonus!(1, on)
      end
    end
    alias_method :record_login!, :record_activity!

    private

    attr_reader :user

    def consecutive?(on)
      user.last_activity_on == on - 1
    end

    def freeze_applicable?(on)
      user.last_activity_on == on - 2 && user.streak_freeze_count > 0
    end

    def grant_streak_bonus!(streak_days, on)
      amount = [ ExpRules::LOGIN_STREAK_BASE_EXP + streak_days, ExpRules::LOGIN_STREAK_MAX_EXP ].min
      ExpGrantService.call(
        user: user, source_type: ExpEvent::LOGIN_STREAK, amount: amount, occurred_on: on
      )
    end

    def grant_freeze_if_milestone!(streak_days)
      return unless [ 7, 14, 30 ].include?(streak_days)
      return if user.streak_freeze_count >= 3

      user.increment!(:streak_freeze_count)
    end
  end
end
