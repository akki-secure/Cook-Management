require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def valid_attributes
    { user: users(:one), recipe: recipes(:two), body: "美味しかったです" }
  end

  test "valid with a body, user, and recipe" do
    comment = Comment.new(valid_attributes)
    assert comment.valid?
  end

  test "invalid without a body" do
    comment = Comment.new(valid_attributes.merge(body: ""))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "invalid without a user" do
    comment = Comment.new(valid_attributes.merge(user: nil))
    assert_not comment.valid?
  end

  test "invalid without a recipe" do
    comment = Comment.new(valid_attributes.merge(recipe: nil))
    assert_not comment.valid?
  end

  test "invalid with a body longer than 1000 characters" do
    comment = Comment.new(valid_attributes.merge(body: "a" * 1001))
    assert_not comment.valid?
  end
end
