require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset" do
    user = users(:one)
    mail = PasswordsMailer.reset(user)

    assert_equal "パスワード再設定のご案内", mail.subject
    assert_equal [ user.email ], mail.to
    assert_match "password_resets", mail.text_part.decoded
  end
end
