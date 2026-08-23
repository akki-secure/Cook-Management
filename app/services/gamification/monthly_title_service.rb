module Gamification
  # 「月に1回、写真付きレシピを投稿する」ことによる月次モンスター付与を担う。
  # 称号自体はレベルアップ時にExpGrantService内のTitleAssignerが更新するため、
  # ここでは月初回投稿の判定とモンスター付与のみを行う。
  class MonthlyTitleService
    def self.call(user:, recipe:)
      new(user: user, recipe: recipe).call
    end

    def initialize(user:, recipe:)
      @user = user
      @recipe = recipe
    end

    def call
      return if already_acquired_this_month?

      monster = pick_monster
      return unless monster

      UserMonster.create!(
        user: user, monster: monster,
        acquired_on: Date.current, acquired_year_month: year_month
      )
    rescue ActiveRecord::RecordNotUnique
      # 同時多重リクエストで既に付与済みだった場合は何もしない
      nil
    end

    private

    attr_reader :user, :recipe

    def year_month
      @year_month ||= recipe.created_at.in_time_zone.strftime("%Y-%m")
    end

    def already_acquired_this_month?
      UserMonster.exists?(user: user, acquired_year_month: year_month)
    end

    def pick_monster
      owned_ids = user.monsters.select(:id)
      pool = Monster.where("unlock_min_level <= ?", user.level).where.not(id: owned_ids)
      pool = Monster.where.not(id: owned_ids) if pool.none?
      pool.order(Arel.sql("RAND()")).first
    end
  end
end
