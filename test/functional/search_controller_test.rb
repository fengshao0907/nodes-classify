require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test "should get nodes" do
    get :nodes
    assert_response :success
  end

  test "should get servers" do
    get :servers
    assert_response :success
  end

end
