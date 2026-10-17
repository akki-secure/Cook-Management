class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    redirect_to root_path, alert: 'お探しのページが見つかりませんでした。'
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: 'ログインしてください。'
  end
end
