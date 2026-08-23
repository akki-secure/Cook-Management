require "test_helper"

class Gamification::MonthlyTitleServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @category = categories(:one)
    Monster.create!(name: "モンスターA", sprite_key: "color:red;shape:circle", unlock_min_level: 1)
    Monster.create!(name: "モンスターB", sprite_key: "color:blue;shape:square", unlock_min_level: 1)
  end

  def build_recipe(title:)
    @user.recipes.create!(title: title, instructions: "焼く", category: @category)
  end

  test "grants one monster for the first photo recipe of the month" do
    recipe = build_recipe(title: "レシピ1")

    assert_difference -> { UserMonster.count }, 1 do
      Gamification::MonthlyTitleService.call(user: @user, recipe: recipe)
    end
  end

  test "does not grant a second monster within the same month" do
    recipe1 = build_recipe(title: "レシピ1")
    recipe2 = build_recipe(title: "レシピ2")

    Gamification::MonthlyTitleService.call(user: @user, recipe: recipe1)

    assert_no_difference -> { UserMonster.count } do
      Gamification::MonthlyTitleService.call(user: @user, recipe: recipe2)
    end
  end
end
