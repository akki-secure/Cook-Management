require "test_helper"

class BattlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires login" do
    get battle_url
    assert_redirected_to login_url
  end

  test "shows the battle page with owned monsters embedded" do
    sign_in_as(@user)
    monster = Monster.create!(name: "テストモンスター", sprite_key: "egg_character.png", hp: 90, attack: 16)
    UserMonster.create!(user: @user, monster: monster, acquired_on: Date.current)

    get battle_url

    assert_response :success
    assert_match "テストモンスター", response.body
  end
end
