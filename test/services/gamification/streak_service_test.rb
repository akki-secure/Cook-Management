require "test_helper"

class Gamification::StreakServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # ---- 通常のストリーク更新 ----

  test "初回投稿でstreak_daysが1になる" do
    @user.update!(last_activity_on: nil, current_streak_days: 0)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 1))
    assert_equal 1, @user.reload.current_streak_days
  end

  test "連続投稿でstreak_daysが加算される" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 3)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 2))
    assert_equal 4, @user.reload.current_streak_days
  end

  test "同じ日に2回呼んでもstreak_daysは変わらない" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 3)
    service = Gamification::StreakService.new(@user)
    service.record_activity!(on: Date.new(2026, 10, 1))
    assert_equal 3, @user.reload.current_streak_days
  end

  # ---- フリーズ救済 ----

  test "1日スキップ + フリーズあり → streakを維持してfreeze_count -1" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 5, streak_freeze_count: 1)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 3))
    @user.reload
    assert_equal 6, @user.current_streak_days
    assert_equal 0, @user.streak_freeze_count
  end

  test "1日スキップ + フリーズなし → streakがリセット" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 5, streak_freeze_count: 0)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 3))
    assert_equal 1, @user.reload.current_streak_days
  end

  test "2日スキップ + フリーズあり → streakがリセット（フリーズは消費しない）" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 5, streak_freeze_count: 1)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 4))
    @user.reload
    assert_equal 1, @user.current_streak_days
    assert_equal 1, @user.streak_freeze_count
  end

  # ---- マイルストーンでフリーズ補充 ----

  test "7日目到達でfreeze_count +1" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 6, streak_freeze_count: 0)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 2))
    assert_equal 1, @user.reload.streak_freeze_count
  end

  test "freeze_countが上限3のときマイルストーンでも増えない" do
    @user.update!(last_activity_on: Date.new(2026, 10, 1), current_streak_days: 6, streak_freeze_count: 3)
    Gamification::StreakService.new(@user).record_activity!(on: Date.new(2026, 10, 2))
    assert_equal 3, @user.reload.streak_freeze_count
  end
end
