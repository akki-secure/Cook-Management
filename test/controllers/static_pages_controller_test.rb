require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "help page is accessible without login" do
    get help_url
    assert_response :success
    assert_match "使い方", response.body
  end

  test "help page explains the main nav items" do
    get help_url
    assert_match "モンスター図鑑", response.body
    assert_match "ログイン", response.body
  end

  test "help link appears in the header for logged-out users" do
    get root_url
    assert_select "a[href=?]", help_path, text: "使い方"
  end

  test "help link appears in the header for logged-in users" do
    sign_in_as(users(:one))
    get root_url
    assert_select "a[href=?]", help_path, text: "使い方"
  end
end
