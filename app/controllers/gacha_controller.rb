class GachaController < ApplicationController
  before_action :require_login

  def show; end

  def create
    result = Gamification::GachaPullService.call(user: current_user)
    respond_to do |format|
      format.html { redirect_after_single_gacha(result) }
      # JSON応答は、ガチャページの演出(コインが落ちる→マシンが揺れる→
      # モンスターが飛び出す)をページ遷移なしでJavaScriptから呼ぶためのもの。
      format.json { render_single_gacha_json(result) }
    end
  end

  def seven
    result = Gamification::SevenGachaPullService.call(user: current_user)
    respond_to do |format|
      format.html { redirect_after_seven_gacha(result) }
      format.json { render_seven_gacha_json(result) }
    end
  end

  private

  def redirect_after_single_gacha(result)
    if result.error == :insufficient_coins
      redirect_to gacha_path, alert: 'コインが足りません。'
    elsif result.error == :monster_limit_reached
      redirect_to gacha_path, alert: 'モンスターの所持数が上限(100体)に達しています。'
    elsif result.hit
      flash[:gacha_result] = { 'monsters' => [monster_payload(result.monster)] }
      redirect_to gacha_path, notice: "🎉 #{result.monster.name} を獲得しました！"
    else
      redirect_to gacha_path, notice: 'ハズレでした…また挑戦してください。'
    end
  end

  def render_single_gacha_json(result)
    if result.error
      render json: { error: result.error.to_s }, status: :unprocessable_content
    else
      render json: { hit: result.hit, monster: result.hit ? monster_payload(result.monster) : nil, coins: current_user.coins }
    end
  end

  def redirect_after_seven_gacha(result)
    if result.error == :insufficient_rainbow_coins
      redirect_to gacha_path, alert: 'レインボーコインが足りません。'
    elsif result.error == :monster_limit_reached
      redirect_to gacha_path, alert: 'モンスターの所持数が上限(100体)に達しています。'
    else
      hit_monsters = result.pulls.filter_map { |pull| pull[:monster] }
      flash[:gacha_result] = { 'monsters' => hit_monsters.map { |m| monster_payload(m) } } if hit_monsters.any?
      redirect_to gacha_path, notice: seven_gacha_message(hit_monsters)
    end
  end

  def render_seven_gacha_json(result)
    if result.error
      render json: { error: result.error.to_s }, status: :unprocessable_content
    else
      render json: {
        pulls: result.pulls.map { |p| { hit: p[:hit], monster: p[:monster] ? monster_payload(p[:monster]) : nil } },
        rainbow_coins: current_user.rainbow_coins
      }
    end
  end

  def seven_gacha_message(hit_monsters)
    if hit_monsters.any?
      "🌈 7連ガチャで#{hit_monsters.size}体獲得！ #{hit_monsters.map(&:name).join('、')}"
    else
      '🌈 7連ガチャ…残念、今回は全てハズレでした。'
    end
  end

  # モンスター獲得時、ガチャページ上で画像付きで見せるための最小限のデータを
  # flashに積む。flashはリダイレクト1回分しか保持されないので、
  # この直後の画面表示だけで消える一時的な演出用データ。
  def monster_payload(monster)
    { 'name' => monster.name, 'sprite_key' => monster.sprite_key }
  end
end
