require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid with a unique name" do
    category = Category.new(name: "新しいカテゴリ")
    assert category.valid?
  end

  test "invalid without a name" do
    category = Category.new(name: "")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "invalid with a duplicate name" do
    category = Category.new(name: categories(:one).name)
    assert_not category.valid?
    assert_includes category.errors[:name], "has already been taken"
  end

  test "cannot be destroyed while it has recipes" do
    category = categories(:one)
    assert_no_difference "Category.count" do
      category.destroy
    end
    assert_includes category.errors[:base], "Cannot delete record because dependent recipes exist"
  end
end
