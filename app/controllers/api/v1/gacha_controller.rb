module Api
  module V1
    class GachaController < BaseController
      def create
        @user = current_api_user
        @result = Gamification::GachaPullService.call(user: @user)

        if @result.error
          render json: { error: @result.error.to_s }, status: :unprocessable_entity
        else
          render status: :created
        end
      end

      def seven
        @user = current_api_user
        @result = Gamification::SevenGachaPullService.call(user: @user)

        if @result.error
          render json: { error: @result.error.to_s }, status: :unprocessable_entity
        else
          render status: :created
        end
      end
    end
  end
end
