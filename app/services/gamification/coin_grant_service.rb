module Gamification
  # コインイベントの記録とユーザーのcoinsキャッシュ更新を担う。
  # amountは正負どちらもありうる(ガチャ消費時は負数)。
  class CoinGrantService
    # @return [Boolean] 実際にコインが付与/消費されたか（重複時はfalse）
    def self.call(user:, source_type:, amount:, source_id: nil, occurred_on: Date.current)
      new(user: user, source_type: source_type, amount: amount, source_id: source_id, occurred_on: occurred_on).call
    end

    def initialize(user:, source_type:, amount:, source_id: nil, occurred_on: Date.current)
      @user = user
      @source_type = source_type
      @amount = amount
      @source_id = source_id
      @occurred_on = occurred_on
    end

    def call
      ActiveRecord::Base.transaction do
        CoinEvent.create!(
          user: user, source_type: source_type, source_id: source_id,
          amount: amount, occurred_on: occurred_on
        )
        user.update!(coins: user.coins + amount)
      end
      true
    rescue ActiveRecord::RecordNotUnique
      # 同一source(同じレシピ等)への二重付与はスキップ
      false
    end

    private

    attr_reader :user, :source_type, :amount, :source_id, :occurred_on
  end
end
