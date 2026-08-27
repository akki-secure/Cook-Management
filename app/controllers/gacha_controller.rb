class GachaController < ApplicationController
  before_action :require_login

  def create
    result = Gamification::GachaPullService.call(user: current_user)

    case
    when result.error == :insufficient_coins
      redirect_to profile_path, alert: "コインが足りません。"
    when result.hit
      redirect_to profile_path, notice: "🎉 #{result.monster.name} を獲得しました！"
    else
      redirect_to profile_path, notice: "ハズレでした…また挑戦してください。"
    end
  end
end
