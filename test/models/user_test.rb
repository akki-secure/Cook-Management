require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_attributes
    { name: "テスト太郎", email: "test-user@example.com", password: "password123", password_confirmation: "password123" }
  end

  test "valid with name, email, and password" do
    user = User.new(valid_attributes)
    assert user.valid?
  end

  test "invalid without a name" do
    user = User.new(valid_attributes.merge(name: ""))
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "invalid without an email" do
    user = User.new(valid_attributes.merge(email: ""))
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with a malformed email" do
    user = User.new(valid_attributes.merge(email: "not-an-email"))
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "invalid with a duplicate email" do
    user = User.new(valid_attributes.merge(email: users(:one).email))
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email is normalized to a stripped, downcased value" do
    user = User.new(valid_attributes.merge(email: "  Test-User@Example.com  "))
    user.valid?
    assert_equal "test-user@example.com", user.email
  end

  test "invalid with a short password" do
    user = User.new(valid_attributes.merge(password: "short", password_confirmation: "short"))
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "destroying a user destroys their recipes" do
    user = users(:one)
    assert_difference "Recipe.count", -user.recipes.count do
      user.destroy
    end
  end
end
