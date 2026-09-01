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

  test "show requires login" do
    get profile_url
    assert_redirected_to login_url
  end

  test "show displays the current user's recipes" do
    sign_in_as(users(:one))
    get profile_url
    assert_response :success
  end

  test "show displays acquired monsters without error" do
    monster = Monster.create!(name: "テストモンスター", sprite_key: "egg_character.png")
    UserMonster.create!(user: users(:one), monster: monster, acquired_on: Date.current)

    sign_in_as(users(:one))
    get profile_url

    assert_response :success
    assert_select "li", text: "テストモンスター"
  end

  test "edit requires login" do
    get edit_profile_url
    assert_redirected_to login_url
  end

  test "update changes name and email without touching password" do
    sign_in_as(users(:one))
    original_digest = users(:one).password_digest

    patch profile_url, params: { user: { name: "新しい名前", email: "changed@example.com", password: "", password_confirmation: "" } }

    assert_redirected_to profile_url
    users(:one).reload
    assert_equal "新しい名前", users(:one).name
    assert_equal "changed@example.com", users(:one).email
    assert_equal original_digest, users(:one).password_digest
  end

  test "update changes password when provided" do
    sign_in_as(users(:one))

    patch profile_url, params: { user: { name: users(:one).name, email: users(:one).email, password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to profile_url
    users(:one).reload
    assert users(:one).authenticate("newpassword123")
  end

  test "update rejects invalid email" do
    sign_in_as(users(:one))

    patch profile_url, params: { user: { name: users(:one).name, email: "not-an-email", password: "", password_confirmation: "" } }

    assert_response :unprocessable_entity
  end
end
