require "test_helper"

class Api::V1::MonstersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = ApiToken.issue!(@user)
    @monster = Monster.create!(name: "テストモンスター", sprite_key: "color:red;shape:circle")
    UserMonster.create!(user: @user, monster: @monster, acquired_on: Date.current)
  end

  test "index returns the user's monsters with a valid token" do
    get api_v1_monsters_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal @monster.name, json.first["name"]
  end

  test "index rejects requests without a token" do
    get api_v1_monsters_url
    assert_response :unauthorized
  end

  test "book returns all monsters with an owned flag, ordered by id" do
    other_monster = Monster.create!(name: "未所持テストモンスター", sprite_key: "egg_character.png")

    get book_api_v1_monsters_url, headers: { "Authorization" => "Bearer #{@token.plain_token}" }
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal Monster.order(:id).pluck(:id), json.map { |m| m["id"] }

    owned_entry = json.find { |m| m["id"] == @monster.id }
    locked_entry = json.find { |m| m["id"] == other_monster.id }

    assert owned_entry["owned"]
    assert_not locked_entry["owned"]
    assert_equal @monster.type_label, owned_entry["type_label"]
    assert_equal @monster.animation_class, owned_entry["animation_class"]
  end

  test "book rejects requests without a token" do
    get book_api_v1_monsters_url
    assert_response :unauthorized
  end
end
