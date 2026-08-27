require "test_helper"

class Api::V1::MonstersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = ApiToken.issue!(@user)
    @monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle", unlock_min_level: 1)
    UserMonster.create!(user: @user, monster: @monster, acquired_on: Date.current)
  end

  test "index returns the user's monsters with a valid token" do
    get api_v1_monsters_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal @monster.name, json.first["name"]
  end

  test "index rejects requests without a token" do
    get api_v1_monsters_url
    assert_response :unauthorized
  end
end
