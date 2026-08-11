require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  test "new is accessible" do
    get new_password_reset_url
    assert_response :success
  end

  test "create sends a reset email for an existing user" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ users(:one) ] do
      post password_resets_url, params: { email: users(:one).email }
    end
    assert_redirected_to login_url
  end

  test "create shows the same success message for a non-existing email" do
    assert_no_enqueued_emails do
      post password_resets_url, params: { email: "nobody@example.com" }
    end
    assert_redirected_to login_url
  end

  test "edit with a valid token is accessible" do
    token = users(:one).generate_token_for(:password_reset)
    get edit_password_reset_url(token)
    assert_response :success
  end

  test "edit with an invalid token redirects" do
    get edit_password_reset_url("bogus-token")
    assert_redirected_to new_password_reset_url
  end

  test "edit with an expired token redirects" do
    token = users(:one).generate_token_for(:password_reset)
    travel 31.minutes
    get edit_password_reset_url(token)
    assert_redirected_to new_password_reset_url
  ensure
    travel_back
  end

  test "update sets a new password with a valid token" do
    token = users(:one).generate_token_for(:password_reset)

    patch password_reset_url(token), params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to login_url
    assert users(:one).reload.authenticate("newpassword123")
  end

  test "update rejects mismatched password confirmation" do
    token = users(:one).generate_token_for(:password_reset)

    patch password_reset_url(token), params: { user: { password: "newpassword123", password_confirmation: "different123" } }

    assert_response :unprocessable_entity
  end

  test "update invalidates the token after the password already changed" do
    token = users(:one).generate_token_for(:password_reset)
    users(:one).update!(password: "changedalready123", password_confirmation: "changedalready123")

    patch password_reset_url(token), params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

    assert_redirected_to new_password_reset_url
  end
end
