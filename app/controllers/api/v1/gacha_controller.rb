module Api
  module V1
    class GachaController < BaseController
      def create
        @user = current_api_user
        @result = Gamification::GachaPullService.call(user: @user)

        if @result.error == :insufficient_coins
          render json: { error: "insufficient_coins" }, status: :unprocessable_entity
        else
          render status: :created
        end
      end
    end
  end
end
