class UsersController < ApplicationController
  before_action :require_login, only: [ :show, :edit, :update ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      AppEventLogger.log(event: "user.signed_up", user: @user)
      redirect_to recipes_path, notice: "アカウントを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @recipes = current_user.recipes.order(created_at: :desc)
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to profile_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
