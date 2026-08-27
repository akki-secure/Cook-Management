require "test_helper"

class Gamification::GachaPullServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle", unlock_min_level: 1)
  end

  test "returns an insufficient_coins error when the user does not have enough coins" do
    @user.update!(coins: Gamification::GachaRules::COST - 1)

    result = Gamification::GachaPullService.call(user: @user)

    assert_equal :insufficient_coins, result.error
    assert_equal Gamification::GachaRules::COST - 1, @user.reload.coins
  end

  test "a hit deducts coins, records the pull, and awards a monster" do
    @user.update!(coins: Gamification::GachaRules::COST)
    service = Gamification::GachaPullService.new(user: @user)

    result = service.stub(:rolled_hit?, true) { service.call }

    assert result.hit
    assert_equal "テストモンスター", result.monster.name
    assert_equal 0, @user.reload.coins
    assert_equal 1, @user.monsters.count
    pull = GachaPull.last
    assert pull.hit
    assert_equal result.monster, pull.monster
  end

  test "a miss deducts coins but awards no monster" do
    @user.update!(coins: Gamification::GachaRules::COST)
    service = Gamification::GachaPullService.new(user: @user)

    result = service.stub(:rolled_hit?, false) { service.call }

    assert_not result.hit
    assert_nil result.monster
    assert_equal 0, @user.reload.coins
    assert_equal 0, @user.monsters.count
    assert_not GachaPull.last.hit
  end
end
