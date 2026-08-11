class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "ログインしてください。"
  end

  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
    payload[:user_id] = current_user&.id
  end
end
