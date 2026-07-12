require "test_helper"

class RecipeTagTest < ActiveSupport::TestCase
  test "valid with a recipe and a tag" do
    recipe_tag = RecipeTag.new(recipe: recipes(:one), tag: tags(:two))
    assert recipe_tag.valid?
  end

  test "invalid without a recipe" do
    recipe_tag = RecipeTag.new(recipe: nil, tag: tags(:one))
    assert_not recipe_tag.valid?
  end

  test "invalid without a tag" do
    recipe_tag = RecipeTag.new(recipe: recipes(:one), tag: nil)
    assert_not recipe_tag.valid?
  end
end
