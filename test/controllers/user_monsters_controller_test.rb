require "test_helper"

class UserMonstersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @monster = Monster.create!(name: "タマゴットン", sprite_key: "egg_character.png", description: "たまごのモンスター。")
    @user_monster = UserMonster.create!(user: @user, monster: @monster, acquired_on: Date.current)
  end

  test "index requires login" do
    get user_monsters_url
    assert_redirected_to login_url
  end

  test "index shows owned monsters" do
    sign_in_as(@user)
    get user_monsters_url

    assert_response :success
    assert_match @monster.name, response.body
  end

  test "destroy releases the selected monster" do
    sign_in_as(@user)

    assert_difference "@user.user_monsters.count", -1 do
      delete user_monsters_url, params: { ids: [ @user_monster.id ] }
      @user.reload
    end

    assert_redirected_to user_monsters_url
    assert_equal "1体のモンスターを逃がしました。", flash[:notice]
  end

  test "destroy does not release another user's monster" do
    other_user_monster = UserMonster.create!(user: @other_user, monster: @monster, acquired_on: Date.current)
    sign_in_as(@user)

    assert_no_difference "UserMonster.count" do
      delete user_monsters_url, params: { ids: [ other_user_monster.id ] }
    end

    assert UserMonster.exists?(other_user_monster.id)
  end
end
