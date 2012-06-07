require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsInitialize < ActiveSupport::TestCase
  def teardown
    delete_wepay_config_file
  end

  test "should initialize WepayRails with settings from wepay.yml" do
    create_wepay_config_file
    initialize_wepay_config
    @gateway = WepayRails::Payments::Gateway.new

    assert_not_nil @gateway.configuration
    assert_equal "http://www.example.com", @gateway.configuration[:root_callback_uri]
  end

  test "should initialize WepayRails with embedded Ruby in wepay.yml.erb" do
    create_wepay_config_file(true)
    initialize_wepay_config
    @gateway = WepayRails::Payments::Gateway.new

    assert_not_nil @gateway.configuration
    assert_equal "http://www.example.com", @gateway.configuration[:root_callback_uri]
    assert_equal 'abc' * 3, @gateway.access_token
  end

  test "should initialize WepayRails with an existing access_token" do
    @gateway = WepayRails::Payments::Gateway.new("myAccessToken")
    assert_equal "myAccessToken", @gateway.access_token
  end
end