require "test_helper"

class BattleResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires login" do
    post battle_results_url, params: { mode: "boss", result: "win" }, as: :json
    assert_redirected_to login_url
  end

  test "awards a rainbow coin on a boss win and returns json" do
    sign_in_as(@user)

    post battle_results_url, params: { mode: "boss", result: "win" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 1, json["rainbow_coins_awarded"]
    assert_equal 1, json["rainbow_coins"]
    assert_equal 1, @user.reload.rainbow_coins
  end

  test "awards nothing on a self-battle win" do
    sign_in_as(@user)

    post battle_results_url, params: { mode: "self", result: "win" }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 0, json["rainbow_coins_awarded"]
  end
end
