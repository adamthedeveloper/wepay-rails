require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsCheckoutMethods < ActiveSupport::TestCase
    include WepayRails::Helpers::ControllerHelpers

  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
    @checkout_params = {
      :amount => 100,
      :short_description => "This is a checkout test!",
      :account_id => "12345"
    }
  end

  def teardown
    delete_wepay_config_file
  end

  test "should create a new WePay checkout object" do
	security_token = Digest::SHA2.hexdigest("1#{Time.now.to_i}")
	stub_request(:post, "https://stage.wepayapi.com/v2/checkout/create").
		with(:body => "callback_uri=http%3A%2F%2Fwww.example.com%2Fwepay%2Fipn%3Fsecurity_token%3D#{security_token}&redirect_uri=http%3A%2F%2Fwww.example.com%2Fwepay%2Fcheckout%3Fsecurity_token%3D#{security_token}&fee_payer=Payee&type=GOODS&charge_tax=0&app_fee=0&auto_capture=1&require_shipping=0&shipping_fee=0&account_id=12345&amount=100&short_description=This%20is%20a%20checkout%20test!",
	       :headers => wepay_gateway.wepay_auth_header).
	  to_return(:status => 200, :body => sample_checkout_response, :headers => {})

    @response = wepay_gateway.perform_checkout(@checkout_params)
    assert_equal "6789", @response[:checkout_id]
    assert_equal "http://stage.wepay.com/api/checkout/6789", @response[:checkout_uri]
    assert_not_nil @response[:security_token]
  end
end

