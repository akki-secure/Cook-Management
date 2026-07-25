require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  def valid_attributes
    { user: users(:one), recipe: recipes(:two) }
  end

  test "valid with a user and recipe" do
    favorite = Favorite.new(valid_attributes)
    assert favorite.valid?
  end

  test "invalid without a user" do
    favorite = Favorite.new(valid_attributes.merge(user: nil))
    assert_not favorite.valid?
  end

  test "invalid without a recipe" do
    favorite = Favorite.new(valid_attributes.merge(recipe: nil))
    assert_not favorite.valid?
  end

  test "invalid when duplicated for the same user and recipe" do
    duplicate = Favorite.new(user: favorites(:one).user, recipe: favorites(:one).recipe)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
