require "test_helper"

class Api::V1::StatusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = ApiToken.issue!(@user)
  end

  test "show returns the user's gamification status with a valid token" do
    get api_v1_status_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @user.level, json["level"]
    assert_equal @user.exp, json["exp"]
  end

  test "show rejects requests without a token" do
    get api_v1_status_url
    assert_response :unauthorized
  end

  test "show rejects requests with an invalid token" do
    get api_v1_status_url, headers: { "Authorization" => "Bearer invalid-token" }
    assert_response :unauthorized
  end
end
