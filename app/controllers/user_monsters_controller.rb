class UserMonstersController < ApplicationController
  before_action :require_login

  def index
    @owned_monsters = current_user.user_monsters.includes(:monster).order(:acquired_on).map do |user_monster|
      monster = user_monster.monster
      { id: user_monster.id, name: monster.name, sprite_key: monster.sprite_key, acquired_on: user_monster.acquired_on }
    end
  end

  def destroy
    # 他ユーザーのUserMonsterを誤って(または意図的に)削除できないよう、
    # 必ずcurrent_userのレコードだけに絞り込んでから削除する。
    released = current_user.user_monsters.where(id: Array(params[:ids])).destroy_all
    redirect_to user_monsters_path, notice: "#{released.size}体のモンスターを逃がしました。"
  end
end
