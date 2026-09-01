require "test_helper"

class Api::V1::GachaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = ApiToken.issue!(@user)
  end

  test "create returns hit result with a valid token" do
    monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    result = Gamification::GachaPullService::Result.new(hit: true, monster: monster, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post api_v1_gacha_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["hit"]
    assert_equal "テストモンスター", json["monster"]["name"]
  end

  test "create returns miss result with a valid token" do
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: nil)

    Gamification::GachaPullService.stub(:call, result) do
      post api_v1_gacha_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_not json["hit"]
    assert_nil json["monster"]
  end

  test "create returns an error when coins are insufficient" do
    result = Gamification::GachaPullService::Result.new(hit: false, monster: nil, error: :insufficient_coins)

    Gamification::GachaPullService.stub(:call, result) do
      post api_v1_gacha_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "insufficient_coins", json["error"]
  end

  test "create rejects requests without a token" do
    post api_v1_gacha_url
    assert_response :unauthorized
  end
end
