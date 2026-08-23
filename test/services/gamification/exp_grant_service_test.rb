require "test_helper"

class Gamification::ExpGrantServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "grants exp and creates an exp_event" do
    assert_difference -> { ExpEvent.count }, 1 do
      result = Gamification::ExpGrantService.call(
        user: @user, source_type: ExpEvent::RECIPE_POST, amount: 30, source_id: 1
      )
      assert result
    end
    assert_equal 30, @user.reload.exp
  end

  test "does not grant exp twice for the same source" do
    Gamification::ExpGrantService.call(user: @user, source_type: ExpEvent::RECIPE_POST, amount: 30, source_id: 1)

    assert_no_difference -> { ExpEvent.count } do
      result = Gamification::ExpGrantService.call(
        user: @user, source_type: ExpEvent::RECIPE_POST, amount: 30, source_id: 1
      )
      assert_not result
    end
    assert_equal 30, @user.reload.exp
  end

  test "updates the user's title when the level threshold is crossed" do
    title = Title.create!(name: "見習い料理人", min_level: 1, rank: 1)
    threshold = Gamification::LevelCalculator.total_exp_required_for_level(2)

    Gamification::ExpGrantService.call(
      user: @user, source_type: ExpEvent::RECIPE_POST, amount: threshold, source_id: 1
    )

    assert_equal title.id, @user.reload.current_title_id
  end
end
