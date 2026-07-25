require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "new is accessible" do
    get login_url
    assert_response :success
  end

  test "create logs in with valid credentials" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    assert_redirected_to recipes_url
    assert_equal users(:one).id, session[:user_id]
  end

  test "create rejects an invalid password" do
    post login_url, params: { email: users(:one).email, password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "create rejects an unknown email" do
    post login_url, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "destroy logs out the current user" do
    sign_in_as(users(:one))
    delete logout_url
    assert_redirected_to login_url
    assert_nil session[:user_id]
  end
end
