require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get characters_index_url
    assert_response :success
  end

  test "should get show" do
    get characters_show_url
    assert_response :success
  end

  test "should get new" do
    get characters_new_url
    assert_response :success
  end

  test "should get edit" do
    get characters_edit_url
    assert_response :success
  end
end
