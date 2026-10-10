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
    @owned_monster_count = current_user.monsters.count
    @contribution_data = contribution_data_for(Time.current.year)
  end

  def contribution
    year = params[:year].to_i
    year = Time.current.year if year < 2000 || year > Time.current.year
    render json: { data: contribution_data_for(year) }
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

  def contribution_data_for(year)
    start_time = Time.new(year, 1, 1).beginning_of_day
    end_time   = Time.new(year, 12, 31).end_of_day
    current_user.recipes
                .where(created_at: start_time..end_time)
                .group('DATE(created_at)')
                .count
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar_image)
  end

  def update_params
    permitted = user_params
    permitted[:password].blank? ? permitted.except(:password, :password_confirmation) : permitted
  end
end
