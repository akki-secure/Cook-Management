class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      AppEventLogger.log(event: "auth.login_succeeded", user: user)
      redirect_to recipes_path, notice: "ログインしました。"
    else
      AppEventLogger.log(event: "auth.login_failed", email: params[:email]&.strip&.downcase)
      flash.now[:alert] = "メールアドレスまたはパスワードが違います。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    AppEventLogger.log(event: "auth.logout", user: current_user)
    session[:user_id] = nil
    redirect_to login_path, notice: "ログアウトしました。"
  end
end
