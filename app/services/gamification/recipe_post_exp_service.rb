module Gamification
  # 写真付きレシピの新規投稿1件に対する一連のゲーミフィケーション処理を統括する
  class RecipePostExpService
    def self.call(user:, recipe:)
      new(user: user, recipe: recipe).call
    end

    def initialize(user:, recipe:)
      @user = user
      @recipe = recipe
    end

    def call
      ExpGrantService.call(
        user: user, source_type: ExpEvent::RECIPE_POST, amount: ExpRules::RECIPE_POST_EXP,
        source_id: recipe.id, occurred_on: recipe.created_at.to_date
      )
      StreakService.new(user).record_activity!(on: recipe.created_at.to_date)
      CoinGrantService.call(
        user: user, source_type: CoinEvent::RECIPE_POST, amount: CoinRules::RECIPE_POST_COINS,
        source_id: recipe.id, occurred_on: recipe.created_at.to_date
      )
    end

    private

    attr_reader :user, :recipe
  end
end
