module Api
  module V1
    class MonstersController < BaseController
      def index
        @user_monsters = current_api_user.user_monsters.includes(:monster).order(:acquired_on)
      end

      # 図鑑用: 所持有無に関わらず全モンスターをNo.順(id順)で返す
      def book
        @monsters = Monster.order(:id)
        @owned_monster_ids = current_api_user.user_monsters.pluck(:monster_id).to_set
      end
    end
  end
end
