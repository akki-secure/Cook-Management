require "test_helper"

class GachaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires login" do
    post gacha_url
    assert_redirected_to login_url
  end

  test "show requires login" do
    get gacha_url
    assert_redirected_to login_url
  end

  test "show renders successfully when logged in" do
    sign_in_as(@user)
    get gacha_url
    assert_response :success
  end

  test "shows an alert when coins are insufficient" do
    sign_in_as(@user)
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: :insufficient_coins)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to gacha_url
    assert_equal "コインが足りません。", flash[:alert]
  end

  test "shows a success notice on a hit" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    result = Gamification::GachaPullService::Result.new(hit: true, monster: monster, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to gacha_url
    assert_match "テストモンスター", flash[:notice]
  end

  test "shows a miss notice on a miss" do
    sign_in_as(@user)
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url
    end

    assert_redirected_to gacha_url
    assert_match "ハズレ", flash[:notice]
  end

  test "seven requires login" do
    post gacha_seven_url
    assert_redirected_to login_url
  end

  test "seven shows an alert when rainbow coins are insufficient" do
    sign_in_as(@user)
    result = Gamification::SevenGachaPullService::Result.new(pulls: [], error: :insufficient_rainbow_coins)

    Gamification::SevenGachaPullService.stub(:call, result) do
      post gacha_seven_url
    end

    assert_redirected_to gacha_url
    assert_equal "レインボーコインが足りません。", flash[:alert]
  end

  test "seven shows a summary notice on success" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    pulls = [ { hit: true, monster: monster } ] + Array.new(6) { { hit: false, monster: nil } }
    result = Gamification::SevenGachaPullService::Result.new(pulls: pulls, error: nil)

    Gamification::SevenGachaPullService.stub(:call, result) do
      post gacha_seven_url
    end

    assert_redirected_to gacha_url
    assert_match "テストモンスター", flash[:notice]
  end

  test "create returns json for the JS-driven gacha widget on a hit" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    result = Gamification::GachaPullService::Result.new(hit: true, monster: monster, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["hit"]
    assert_equal "テストモンスター", json["monster"]["name"]
  end

  test "create returns json error when coins are insufficient" do
    sign_in_as(@user)
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: :insufficient_coins)

    Gamification::GachaPullService.stub(:call, result) do
      post gacha_url, as: :json
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "insufficient_coins", json["error"]
  end

  test "seven returns json with pulls for the JS-driven gacha widget" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    pulls = [ { hit: true, monster: monster } ] + Array.new(6) { { hit: false, monster: nil } }
    result = Gamification::SevenGachaPullService::Result.new(pulls: pulls, error: nil)

    Gamification::SevenGachaPullService.stub(:call, result) do
      post gacha_seven_url, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 7, json["pulls"].size
    assert_equal "テストモンスター", json["pulls"].first["monster"]["name"]
  end
end
