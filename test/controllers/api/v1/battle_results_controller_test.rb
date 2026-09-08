require "test_helper"

class Api::V1::BattleResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = ApiToken.issue!(@user)
  end

  test "awards a rainbow coin on a boss win" do
    post api_v1_battle_results_url, params: { mode: "boss", result: "win" },
      headers: { "Authorization" => "Bearer #{@token.plain_token}" }

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 1, json["rainbow_coins_awarded"]
    assert_equal 1, @user.reload.rainbow_coins
  end

  test "rejects requests without a token" do
    post api_v1_battle_results_url, params: { mode: "boss", result: "win" }
    assert_response :unauthorized
  end
end
