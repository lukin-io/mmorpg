require "test_helper"

class RegionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get regions_index_url
    assert_response :success
  end

  test "should get show" do
    get regions_show_url
    assert_response :success
  end

  test "should get new" do
    get regions_new_url
    assert_response :success
  end

  test "should get edit" do
    get regions_edit_url
    assert_response :success
  end
end
