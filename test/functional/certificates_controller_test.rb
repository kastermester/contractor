require 'test_helper'

class CertificatesControllerTest < ActionController::TestCase
  setup do
    @certificate = certificates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:certificates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create certificate" do
    assert_difference('Certificate.count', 1) do
      post :create, certificate: {
        :name => "Test",
        :email => "test@test.com",
        :common_name => "Test",
        :expires => Time.now+3600,
        :issuer_certificate => ""
      }
    end

    assert_redirected_to certificate_path(assigns(:certificate))
  end

  test "should show certificate" do
    get :show, id: @certificate
    assert_response :success
  end

  test "should revoke certificate" do
    assert_difference('Certificate.count', -1) do
      delete :destroy, id: @certificate
    end

    assert_redirected_to certificates_path
  end
end
