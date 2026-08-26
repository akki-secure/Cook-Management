require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "create issues a token with valid credentials" do
    assert_difference -> { ApiToken.count }, 1 do
      post api_v1_auth_url, params: { email: users(:one).email, password: "password123" }
    end
    assert_response :created
    json = JSON.parse(response.body)
    assert json["token"].present?
    assert_equal users(:one).id, json["user"]["id"]
  end

  test "create rejects invalid credentials" do
    assert_no_difference -> { ApiToken.count } do
      post api_v1_auth_url, params: { email: users(:one).email, password: "wrongpassword" }
    end
    assert_response :unauthorized
  end
end
