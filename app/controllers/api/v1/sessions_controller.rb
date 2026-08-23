module Api
  module V1
    class SessionsController < ActionController::Base
      skip_forgery_protection

      before_action { request.format = :json }

      def create
        user = User.find_by(email: params[:email]&.strip&.downcase)

        if user&.authenticate(params[:password])
          token = ApiToken.issue!(user)
          render json: { token: token.plain_token, user: { id: user.id, name: user.name } }, status: :created
        else
          render json: { error: "メールアドレスまたはパスワードが違います。" }, status: :unauthorized
        end
      end
    end
  end
end
