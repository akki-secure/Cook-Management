class PasswordResetsController < ApplicationController
  before_action :set_user_from_token, only: [ :edit, :update ]

  def new
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)
    PasswordsMailer.reset(user).deliver_later if user

    redirect_to login_path, notice: "パスワード再設定用のメールを送信しました。届いていない場合は、メールアドレスをご確認ください。"
  end

  def edit
  end

  def update
    if @user.update(password_params)
      redirect_to login_path, notice: "パスワードを再設定しました。ログインしてください。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_from_token
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_path, alert: "リンクの有効期限が切れているか、無効です。もう一度お試しください。"
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
