module Api
  module V1
    # Godotクライアント向けAPIの共通処理。セッション認証は使わず、
    # Authorization: Bearer <token> ヘッダーのAPIトークンでユーザーを特定する。
    class BaseController < ActionController::Base
      skip_forgery_protection

      before_action { request.format = :json }
      before_action :authenticate_api_user!

      private

      attr_reader :current_api_user

      def authenticate_api_user!
        @current_api_user = ApiToken.authenticate(bearer_token)
        render json: { error: "ログインが必要です。" }, status: :unauthorized unless @current_api_user
      end

      def bearer_token
        request.headers["Authorization"]&.split(" ")&.last
      end
    end
  end
end
