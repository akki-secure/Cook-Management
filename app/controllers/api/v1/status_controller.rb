module Api
  module V1
    class StatusController < BaseController
      def show
        @user = current_api_user
      end
    end
  end
end
