class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email]&.strip&.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to recipes_path, notice: "ログインしました。"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが違います。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "ログアウトしました。"
  end
end
