require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsAuthorize < ActiveSupport::TestCase
  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
    @gateway = WepayRails::Payments::Gateway.new
  end

  def teardown
    delete_wepay_config_file
  end

  test "WePay gateway should have correct authorize url" do
    @url = @gateway.auth_code_url("http://www.example.com")
    assert @url.match("https://stage.wepayapi.com/v2/oauth2/authorize"), "<https://stage.wepayapi.com/v2/oauth2/authorize> expected but was #{@url}"
  end

  test "should raise errors when authorizing an invalid auth code" do
    assert_raise WepayRails::Exceptions::ExpiredTokenError do
      @gateway.get_access_token("authCode", "http://www.example.com")
    end
  end

  # ToDo: Need to add test for actual authorization process, but we first need a valid auth code
  # to exchange for an access token without raising errors.  Not sure the best way to simulate
  # this process within the test suite.
end