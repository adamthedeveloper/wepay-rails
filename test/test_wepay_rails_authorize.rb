require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsAuthorize < ActiveSupport::TestCase
  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
  end

  def teardown
    delete_wepay_config_file
  end

  test "WePay gateway should have correct authorize url" do
	@gateway = WepayRails::Payments::Gateway.new
    @url = @gateway.auth_code_url("http://www.example.com")
    assert @url.match("https://stage.wepay.com/v2/oauth2/authorize"), "<https://stage.wepayapi.com/v2/oauth2/authorize> expected but was #{@url}"
  end

  test "should raise errors when authorizing an invalid auth code" do
	@gateway = WepayRails::Payments::Gateway.new("notAnAccessToken")
	stub_request(:post, "https://stage.wepayapi.com/v2/oauth2/token").
		with(:body => "client_id=168738&client_secret=8d701ad2ac&redirect_uri=http%3A%2F%2Fwww.example.com&code=authCode",
	         :headers => {'Authorization'=>'Bearer: notAnAccessToken', 'User-Agent'=>'WepayRails'}).
		to_return(:status => 200, :body => {:error_description => 'invalid code parameter'}.to_json, :headers => {})
    assert_raise WepayRails::Exceptions::AccessTokenError do
      @gateway.get_access_token("authCode", "http://www.example.com")
    end
  end

  # ToDo: Add test for successful authorization
end