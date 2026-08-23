module Gamification
  # ユーザーの現在レベルに応じた称号を再評価し、変化があれば更新する
  class TitleAssigner
    def initialize(user)
      @user = user
    end

    def call
      new_title = Title.where("min_level <= ?", user.level).order(min_level: :desc).first
      return if new_title.nil? || user.current_title_id == new_title.id

      user.update!(current_title_id: new_title.id)
      UserTitle.create!(user: user, title: new_title, awarded_on: Date.current)
    end

    private

    attr_reader :user
  end
end
