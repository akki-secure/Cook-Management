require "test_helper"

class Gamification::CoinGrantServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "grants coins and creates a coin_event" do
    assert_difference -> { CoinEvent.count }, 1 do
      result = Gamification::CoinGrantService.call(
        user: @user, source_type: CoinEvent::RECIPE_POST, amount: 1, source_id: 1
      )
      assert result
    end
    assert_equal 1, @user.reload.coins
  end

  test "does not grant coins twice for the same source" do
    Gamification::CoinGrantService.call(user: @user, source_type: CoinEvent::RECIPE_POST, amount: 1, source_id: 1)

    assert_no_difference -> { CoinEvent.count } do
      result = Gamification::CoinGrantService.call(
        user: @user, source_type: CoinEvent::RECIPE_POST, amount: 1, source_id: 1
      )
      assert_not result
    end
    assert_equal 1, @user.reload.coins
  end

  test "supports negative amounts for spending coins" do
    Gamification::CoinGrantService.call(user: @user, source_type: CoinEvent::RECIPE_POST, amount: 10, source_id: 1)
    Gamification::CoinGrantService.call(user: @user, source_type: CoinEvent::GACHA_PULL, amount: -5, source_id: 99)

    assert_equal 5, @user.reload.coins
  end
end
