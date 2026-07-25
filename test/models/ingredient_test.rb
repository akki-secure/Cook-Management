require "test_helper"

class IngredientTest < ActiveSupport::TestCase
  test "valid with a name and a recipe" do
    ingredient = Ingredient.new(name: "にんじん", quantity: "1本", recipe: recipes(:one))
    assert ingredient.valid?
  end

  test "invalid without a name" do
    ingredient = Ingredient.new(name: "", recipe: recipes(:one))
    assert_not ingredient.valid?
    assert_includes ingredient.errors[:name], "can't be blank"
  end

  test "invalid without a recipe" do
    ingredient = Ingredient.new(name: "にんじん", recipe: nil)
    assert_not ingredient.valid?
  end
end
