require "test_helper"

class RatingTest < ActiveSupport::TestCase
  def valid_attributes
    { user: users(:one), recipe: recipes(:two), score: 3 }
  end

  test "valid with a score between 1 and 5" do
    rating = Rating.new(valid_attributes)
    assert rating.valid?
  end

  test "invalid without a score" do
    rating = Rating.new(valid_attributes.merge(score: nil))
    assert_not rating.valid?
  end

  test "invalid with a score of 0" do
    rating = Rating.new(valid_attributes.merge(score: 0))
    assert_not rating.valid?
  end

  test "invalid with a score of 6" do
    rating = Rating.new(valid_attributes.merge(score: 6))
    assert_not rating.valid?
  end

  test "invalid when duplicated for the same user and recipe" do
    duplicate = Rating.new(user: ratings(:one).user, recipe: ratings(:one).recipe, score: 2)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
