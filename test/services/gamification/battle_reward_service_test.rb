require "test_helper"

class Gamification::BattleRewardServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "awards a rainbow coin on a boss battle win" do
    result = Gamification::BattleRewardService.call(user: @user, mode: "boss", result: "win")

    assert_equal 1, result.rainbow_coins_awarded
    assert_equal 1, @user.reload.rainbow_coins
  end

  test "awards nothing on a boss battle loss" do
    result = Gamification::BattleRewardService.call(user: @user, mode: "boss", result: "lose")

    assert_equal 0, result.rainbow_coins_awarded
    assert_equal 0, @user.reload.rainbow_coins
  end

  test "awards nothing on a self-battle win" do
    result = Gamification::BattleRewardService.call(user: @user, mode: "self", result: "win")

    assert_equal 0, result.rainbow_coins_awarded
    assert_equal 0, @user.reload.rainbow_coins
  end
end
