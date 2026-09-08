require "test_helper"

class Gamification::SevenGachaPullServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
  end

  test "returns an insufficient_rainbow_coins error when the user has none" do
    @user.update!(rainbow_coins: 0)

    result = Gamification::SevenGachaPullService.call(user: @user)

    assert_equal :insufficient_rainbow_coins, result.error
    assert_equal [], result.pulls
  end

  test "consumes one rainbow coin and rolls seven times" do
    @user.update!(rainbow_coins: 1)

    result = Gamification::SevenGachaPullService.call(user: @user)

    assert_nil result.error
    assert_equal 7, result.pulls.size
    assert_equal 0, @user.reload.rainbow_coins
  end

  test "does not touch the normal coin balance" do
    @user.update!(rainbow_coins: 1, coins: 5)

    Gamification::SevenGachaPullService.call(user: @user)

    assert_equal 5, @user.reload.coins
  end
end
