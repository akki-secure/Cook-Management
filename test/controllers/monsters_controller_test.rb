require "test_helper"

class MonstersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @owned_monster = Monster.create!(name: "タマゴットン", sprite_key: "egg_character.png", description: "たまごのモンスター。")
    @locked_monster = Monster.create!(name: "ミルクドロップ", sprite_key: "milk.png", description: "ミルクのモンスター。")
    UserMonster.create!(user: @user, monster: @owned_monster, acquired_on: Date.current)
  end

  test "index requires login" do
    get monsters_url
    assert_redirected_to login_url
  end

  test "show requires login" do
    get monster_url(@owned_monster)
    assert_redirected_to login_url
  end

  test "index shows owned monster name and hides locked monster name" do
    sign_in_as(@user)
    get monsters_url

    assert_response :success
    assert_match @owned_monster.name, response.body
    assert_no_match @locked_monster.name, response.body
    assert_match "？？？", response.body
  end

  test "index shows the owned count" do
    sign_in_as(@user)
    get monsters_url

    assert_match "所持数 1 / 全2体", response.body
  end

  test "show displays details for an owned monster" do
    sign_in_as(@user)
    get monster_url(@owned_monster)

    assert_response :success
    assert_match @owned_monster.name, response.body
    assert_match @owned_monster.description, response.body
  end

  test "show hides details for a locked monster" do
    sign_in_as(@user)
    get monster_url(@locked_monster)

    assert_response :success
    assert_match "？？？", response.body
    assert_match "まだ出会っていない", response.body
    assert_no_match @locked_monster.description, response.body
  end

  test "show has no prev link on the first monster and no next link on the last" do
    sign_in_as(@user)

    get monster_url(@owned_monster)
    assert_select "a[aria-label=?]", "前のモンスター", count: 0

    get monster_url(@locked_monster)
    assert_select "a[aria-label=?]", "次のモンスター", count: 0
  end

  test "show redirects to the index when the monster does not exist" do
    sign_in_as(@user)
    get monster_url(id: 0)

    assert_redirected_to monsters_url
  end
end
