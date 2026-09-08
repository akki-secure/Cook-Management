module Api
  module V1
    class BattleResultsController < BaseController
      def create
        @user = current_api_user
        @reward = Gamification::BattleRewardService.call(
          user: @user, mode: params[:mode], result: params[:result]
        )
        render status: :created
      end
    end
  end
end
