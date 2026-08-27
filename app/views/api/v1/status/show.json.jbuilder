json.level @user.level
json.exp @user.exp
json.next_level_exp Gamification::LevelCalculator.next_level_total_exp(@user.exp)
json.current_title @user.current_title&.name
json.current_streak_days @user.current_streak_days
json.longest_streak_days @user.longest_streak_days
json.coins @user.coins
