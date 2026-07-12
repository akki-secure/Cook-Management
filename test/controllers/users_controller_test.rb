require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def valid_params
    { user: { name: "新規ユーザー", email: "newuser@example.com", password: "password123", password_confirmation: "password123" } }
  end

  test "new is accessible" do
    get signup_url
    assert_response :success
  end

  test "create signs up a valid user and logs them in" do
    assert_difference "User.count", 1 do
      post signup_url, params: valid_params
    end

    user = User.order(:created_at).last
    assert_redirected_to recipes_url
    assert_equal user.id, session[:user_id]
  end

  test "create rejects a duplicate email" do
    assert_no_difference "User.count" do
      post signup_url, params: { user: valid_params[:user].merge(email: users(:one).email) }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects a mismatched password confirmation" do
    assert_no_difference "User.count" do
      post signup_url, params: { user: valid_params[:user].merge(password_confirmation: "different123") }
    end
    assert_response :unprocessable_entity
  end
end
