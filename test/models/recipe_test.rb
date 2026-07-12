require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  def valid_attributes
    { title: "新しいレシピ", user: users(:one), category: categories(:one) }
  end

  test "valid with a title, user, and category" do
    recipe = Recipe.new(valid_attributes)
    assert recipe.valid?
  end

  test "invalid without a title" do
    recipe = Recipe.new(valid_attributes.merge(title: ""))
    assert_not recipe.valid?
    assert_includes recipe.errors[:title], "can't be blank"
  end

  test "invalid without a user" do
    recipe = Recipe.new(valid_attributes.merge(user: nil))
    assert_not recipe.valid?
  end

  test "invalid without a category" do
    recipe = Recipe.new(valid_attributes.merge(category: nil))
    assert_not recipe.valid?
  end

  test "invalid with a non-positive cooking_time" do
    recipe = Recipe.new(valid_attributes.merge(cooking_time: 0))
    assert_not recipe.valid?
    assert_includes recipe.errors[:cooking_time], "must be greater than 0"
  end

  test "invalid with a non-positive servings" do
    recipe = Recipe.new(valid_attributes.merge(servings: -1))
    assert_not recipe.valid?
    assert_includes recipe.errors[:servings], "must be greater than 0"
  end

  test "valid with nil cooking_time and servings" do
    recipe = Recipe.new(valid_attributes.merge(cooking_time: nil, servings: nil))
    assert recipe.valid?
  end

  test "destroying a recipe destroys its ingredients" do
    recipe = recipes(:one)
    assert_difference "Ingredient.count", -recipe.ingredients.count do
      recipe.destroy
    end
  end

  test "destroying a recipe destroys its recipe_tags but not its tags" do
    recipe = recipes(:one)
    assert_difference "RecipeTag.count", -1 do
      assert_no_difference "Tag.count" do
        recipe.destroy
      end
    end
  end

  test "nested ingredient with blank name is rejected" do
    recipe = Recipe.new(valid_attributes)
    recipe.ingredients_attributes = [ { name: "", quantity: "1個" } ]
    assert recipe.save
    assert_equal 0, recipe.ingredients.count
  end

  test "search_by_keyword matches title" do
    results = Recipe.search_by_keyword("肉じゃが")
    assert_includes results, recipes(:one)
    assert_not_includes results, recipes(:two)
  end

  test "search_by_keyword returns everything when blank" do
    assert_equal Recipe.count, Recipe.search_by_keyword(nil).count
  end

  test "in_category filters by category" do
    results = Recipe.in_category(categories(:one).id)
    assert_includes results, recipes(:one)
    assert_not_includes results, recipes(:two)
  end

  test "tagged_with filters by tag" do
    results = Recipe.tagged_with(tags(:one).id)
    assert_includes results, recipes(:one)
    assert_not_includes results, recipes(:two)
  end
end
