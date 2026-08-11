class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "パスワード再設定のご案内"
  end
end
