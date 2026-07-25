require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid with a unique name" do
    tag = Tag.new(name: "新しいタグ")
    assert tag.valid?
  end

  test "invalid without a name" do
    tag = Tag.new(name: "")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "invalid with a duplicate name" do
    tag = Tag.new(name: tags(:one).name)
    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end

  test "destroying a tag destroys its recipe_tags but not its recipes" do
    tag = tags(:one)
    assert_difference "RecipeTag.count", -1 do
      assert_no_difference "Recipe.count" do
        tag.destroy
      end
    end
  end
end
