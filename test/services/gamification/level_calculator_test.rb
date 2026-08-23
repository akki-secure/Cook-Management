require "test_helper"

class Gamification::LevelCalculatorTest < ActiveSupport::TestCase
  test "level 1 requires 0 total exp" do
    assert_equal 0, Gamification::LevelCalculator.total_exp_required_for_level(1)
  end

  test "exp curve increases as level increases" do
    early = Gamification::LevelCalculator.exp_to_next_level(2)
    late = Gamification::LevelCalculator.exp_to_next_level(80)
    assert late > early
  end

  test "exp_to_next_level returns nil at max level" do
    assert_nil Gamification::LevelCalculator.exp_to_next_level(100)
  end

  test "level_for_total_exp returns 1 when exp is 0" do
    assert_equal 1, Gamification::LevelCalculator.level_for_total_exp(0)
  end

  test "level_for_total_exp returns the correct level at an exact threshold" do
    threshold = Gamification::LevelCalculator.total_exp_required_for_level(10)
    assert_equal 10, Gamification::LevelCalculator.level_for_total_exp(threshold)
    assert_equal 9, Gamification::LevelCalculator.level_for_total_exp(threshold - 1)
  end

  test "level_for_total_exp caps at 100" do
    assert_equal 100, Gamification::LevelCalculator.level_for_total_exp(999_999_999)
  end

  test "next_level_total_exp returns nil at max level" do
    assert_nil Gamification::LevelCalculator.next_level_total_exp(999_999_999)
  end
end
