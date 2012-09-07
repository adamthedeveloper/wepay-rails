require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsAccountMethods < ActiveSupport::TestCase

  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
  end

  def teardown
    delete_wepay_config_file
  end

  test "should raise error from WePay when using invalid access token" do
	stub_request(:post, "https://stage.wepayapi.com/v2/account/create").
	  with(:body => "name=Example%20Account&description=This%20is%20just%20an%20example%20WePay%20account.",
	       :headers => wepay_gateway.wepay_auth_header.merge('Authorization' => "Bearer: notAnAccessToken")).
	  to_return({:status => 401, :body => {:error_description => 'a valid access_token is required'}.to_json})
    assert_raise WepayRails::Exceptions::ExpiredTokenError do
      wepay_gateway = WepayRails::Payments::Gateway.new("notAnAccessToken")
      wepay_gateway.create_account({
        :name => "Example Account",
        :description => "This is just an example WePay account."
      })
    end
  end

  test "should create new WePay account" do
	stub_request(:post, "https://stage.wepayapi.com/v2/account/create").
	  with(:body => "name=Example%20Account&description=This%20is%20just%20an%20example%20WePay%20account.", :headers => wepay_gateway.wepay_auth_header).
	  to_return({:status => 200, :body => sample_account_response})
    @response = wepay_gateway.create_account({
        :name => "Example Account",
        :description => "This is just an example WePay account."
    })

    assert_not_nil @response[:account_id]
    assert_not_nil @response[:account_uri]
  end

  test "should get WePay account" do
    stub_request(:post, "https://stage.wepayapi.com/v2/account").
	  with(:body => "account_id=12345", :headers => wepay_gateway.wepay_auth_header).
	  to_return(:status => 200, :body => sample_account_response)
    @response = wepay_gateway.get_account(12345)

    assert_not_nil @response[:name]
    assert_equal "Example Account", @response[:name]
    assert_equal "This is just an example WePay account.", @response[:description]
  end

  test "should find WePay account by reference id or name" do
	stub_request(:post, "https://stage.wepayapi.com/v2/account/find").
	  with(:body => "reference_id=wepayrailstestaccount123", :headers => wepay_gateway.wepay_auth_header).
	  to_return({:status => 200, :body => sample_find_response, :headers => {}})
    @response = wepay_gateway.find_account(:reference_id => "wepayrailstestaccount123")

    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"
    assert_equal 1, @response.length
    assert_equal "Custom Reference ID", @response.first[:name]
  end

  test "should find all WePay accounts for current authorized user" do
	stub_request(:post, "https://stage.wepayapi.com/v2/account/find").
	  with(:headers => wepay_gateway.wepay_auth_header).
	  to_return({:status => 200, :body => sample_find_response, :headers => {}})
    @response = wepay_gateway.find_account
    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"
    assert_equal "Custom Reference ID", @response.last[:name]
  end

  test "should modify WePay account" do
	options = { :name => "This is a new Name!",
				:description => "This is a new description!" }
	stub_request(:post, "https://stage.wepayapi.com/v2/account/modify").
	  with(:headers => wepay_gateway.wepay_auth_header).
	  to_return({:status => 200, :body => sample_account_response(options), :headers => {}})
    @response = wepay_gateway.modify_account(12345, options)

    assert_not_nil @response[:account_id]
    assert_equal "This is a new Name!", @response[:name]
    assert_equal "This is a new description!", @response[:description]
  end

  test "should get current balance of WePay account" do
    stub_request(:post, "https://stage.wepayapi.com/v2/account/balance").
	  with(:headers => wepay_gateway.wepay_auth_header).
	  to_return({:status => 200, :body => sample_balance_response, :headers => {}})
    @response = wepay_gateway.get_account_balance(12345)

    assert_equal "500", @response[:pending_balance]
    assert_equal "500", @response[:available_balance]
    assert_equal "USD", @response[:currency]
  end

  test "should delete WePay account" do
	stub_request(:post, "https://stage.wepayapi.com/v2/account/delete").
	  with(:body => "account_id=12345", :headers => wepay_gateway.wepay_auth_header).
	  to_return(:status => 200, :body => sample_account_response, :headers => {})
    @response = wepay_gateway.delete_account(12345)

    assert_not_nil @response[:account_id]
	assert_equal "12345", @response[:account_id]
  end
end
