class MonstersController < ApplicationController
  before_action :require_login

  def index
    @monsters = Monster.order(:id)
    @owned_monster_ids = current_user.user_monsters.pluck(:monster_id).to_set
  end

  def show
    @monsters = Monster.order(:id).to_a
    index_in_list = @monsters.find_index { |monster| monster.id == params[:id].to_i }
    return redirect_to monsters_path, alert: "そのモンスターは見つかりませんでした。" if index_in_list.nil?

    @monster = @monsters[index_in_list]
    @display_number = index_in_list + 1
    @prev_monster, @next_monster = neighboring_monsters(index_in_list)
    @owned = current_user.user_monsters.exists?(monster_id: @monster.id)
  end

  private

  def neighboring_monsters(index_in_list)
    prev_monster = @monsters[index_in_list - 1] if index_in_list.positive?
    [ prev_monster, @monsters[index_in_list + 1] ]
  end
end
