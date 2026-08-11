class UsersController < ApplicationController
  before_action :require_login, only: [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to recipes_path, notice: "アカウントを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @recipes = current_user.recipes
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(update_params)
      redirect_to profile_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def update_params
    permitted = user_params
    permitted[:password].blank? ? permitted.except(:password, :password_confirmation) : permitted
  end
end
