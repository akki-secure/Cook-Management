module Api
  module V1
    class MonstersController < BaseController
      def index
        @user_monsters = current_api_user.user_monsters.includes(:monster).order(:acquired_on)
      end
    end
  end
end
