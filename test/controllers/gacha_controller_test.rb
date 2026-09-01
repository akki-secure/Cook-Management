require "test_helper"

class GachaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires login" do
    post gacha_url
    assert_redirected_to login_url
  end

  test "shows an alert when coins are insufficient" do
    sign_in_as(@user)
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: :insufficient_coins)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to profile_url
    assert_equal "コインが足りません。", flash[:alert]
  end

  test "shows a success notice on a hit" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    result = Gamification::GachaPullService::Result.new(hit: true, monster: monster, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to profile_url
    assert_match "テストモンスター", flash[:notice]
  end

  test "shows a miss notice on a miss" do
    sign_in_as(@user)
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to profile_url
    assert_match "ハズレ", flash[:notice]
  end
end
