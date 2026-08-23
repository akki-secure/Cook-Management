module Gamification
  # レベル1〜100のEXPカーブに関する純粋関数群。副作用を持たない。
  class LevelCalculator
    MAX_LEVEL = 100

    class << self
      # レベルNからN+1に必要な差分EXP
      def exp_to_next_level(level)
        return nil if level >= MAX_LEVEL

        100 + 15 * ((level - 1)**2)
      end

      # そのレベルに到達するために必要な累積EXP
      def total_exp_required_for_level(level)
        cumulative_table[level]
      end

      # 累積EXPから現在のレベルを算出
      def level_for_total_exp(total_exp)
        (1..MAX_LEVEL).to_a.reverse.find { |level| cumulative_table[level] <= total_exp } || 1
      end

      # 次のレベルまでに必要な累積EXP（カンスト時はnil）
      def next_level_total_exp(total_exp)
        level = level_for_total_exp(total_exp)
        return nil if level >= MAX_LEVEL

        cumulative_table[level + 1]
      end

      private

      def cumulative_table
        @cumulative_table ||= begin
          table = Array.new(MAX_LEVEL + 1)
          table[1] = 0
          (2..MAX_LEVEL).each do |level|
            table[level] = table[level - 1] + exp_to_next_level(level - 1)
          end
          table
        end
      end
    end
  end
end
