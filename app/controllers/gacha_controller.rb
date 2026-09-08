class GachaController < ApplicationController
  before_action :require_login

  def create
    result = Gamification::GachaPullService.call(user: current_user)

    respond_to do |format|
      format.html do
        case
        when result.error == :insufficient_coins
          redirect_to profile_path, alert: "コインが足りません。"
        when result.hit
          flash[:gacha_result] = { "monsters" => [ monster_payload(result.monster) ] }
          redirect_to profile_path, notice: "🎉 #{result.monster.name} を獲得しました！"
        else
          redirect_to profile_path, notice: "ハズレでした…また挑戦してください。"
        end
      end

      # JSON応答は、マイページのガチャ演出(コインが落ちる→マシンが揺れる→
      # モンスターが飛び出す)をページ遷移なしでJavaScriptから呼ぶためのもの。
      format.json do
        if result.error == :insufficient_coins
          render json: { error: "insufficient_coins" }, status: :unprocessable_entity
        else
          render json: {
            hit: result.hit,
            monster: result.hit ? monster_payload(result.monster) : nil,
            coins: current_user.coins
          }
        end
      end
    end
  end

  def seven
    result = Gamification::SevenGachaPullService.call(user: current_user)

    respond_to do |format|
      format.html do
        if result.error == :insufficient_rainbow_coins
          redirect_to profile_path, alert: "レインボーコインが足りません。"
        else
          hit_monsters = result.pulls.filter_map { |pull| pull[:monster] }
          hit_count = hit_monsters.size
          names = hit_monsters.map(&:name).join("、")
          message = hit_count.positive? ? "🌈 7連ガチャで#{hit_count}体獲得！ #{names}" : "🌈 7連ガチャ…残念、今回は全てハズレでした。"
          flash[:gacha_result] = { "monsters" => hit_monsters.map { |m| monster_payload(m) } } if hit_count.positive?
          redirect_to profile_path, notice: message
        end
      end

      format.json do
        if result.error == :insufficient_rainbow_coins
          render json: { error: "insufficient_rainbow_coins" }, status: :unprocessable_entity
        else
          render json: {
            pulls: result.pulls.map { |p| { hit: p[:hit], monster: p[:monster] ? monster_payload(p[:monster]) : nil } },
            rainbow_coins: current_user.rainbow_coins
          }
        end
      end
    end
  end

  private

  # モンスター獲得時、マイページ上で(Godot版のガチャ演出のように)画像付きで
  # 見せるための最小限のデータをflashに積む。flashはリダイレクト1回分しか
  # 保持されないので、この直後の画面表示だけで消える一時的な演出用データ。
  def monster_payload(monster)
    { "name" => monster.name, "sprite_key" => monster.sprite_key }
  end
end
