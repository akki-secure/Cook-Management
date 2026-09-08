class BattleResultsController < ApplicationController
  before_action :require_login

  def create
    reward = Gamification::BattleRewardService.call(
      user: current_user, mode: params[:mode], result: params[:result]
    )
    render json: { rainbow_coins_awarded: reward.rainbow_coins_awarded, rainbow_coins: current_user.rainbow_coins }
  end
end
