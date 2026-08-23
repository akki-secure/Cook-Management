require "test_helper"

class Gamification::RecipePostExpServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:one)
    Title.create!(name: "見習い料理人", min_level: 1, rank: 1)
    Monster.create!(name: "モンスターA", sprite_key: "color:red;shape:circle", unlock_min_level: 1)
  end

  test "grants exp, updates streak, and awards the monthly monster" do
    recipe = @user.recipes.create!(title: "テストレシピ", instructions: "焼く", category: @category)

    Gamification::RecipePostExpService.call(user: @user, recipe: recipe)
    @user.reload

    assert_equal Gamification::ExpRules::RECIPE_POST_EXP + Gamification::ExpRules::LOGIN_STREAK_BASE_EXP + 1, @user.exp
    assert_equal 1, @user.current_streak_days
    assert_equal 1, @user.monsters.count
    assert_equal "見習い料理人", @user.current_title.name
  end
end
