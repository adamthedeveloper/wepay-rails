require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsPreapprovalMethods < ActiveSupport::TestCase
  include WepayRails::Helpers::ControllerHelpers

  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
    @checkout_params = {
      :amount => 300,
      :period => "once",
      :short_description => "This is a checkout test!",
      :account_id => "12345"
    }
  end

  def teardown
    delete_wepay_config_file
  end

  test "should create a new WePay preapproval object" do
  stub_request(:post, "https://stage.wepayapi.com/v2/preapproval/create").
      with(:headers => wepay_gateway.wepay_auth_header).
      to_return(:status => 200, :body => sample_preapproval_response, :headers => {})

    @response = wepay_gateway.perform_preapproval(@checkout_params)
    assert_equal "6789", @response[:preapproval_id]
    assert_equal "http://stage.wepay.com/api/preapproval/6789", @response[:preapproval_uri]
    assert_not_nil @response[:security_token]
  end
end