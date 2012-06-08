require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsAccountMethods < ActiveSupport::TestCase
  # ToDo: Remove actual API calls in favor of stubs

  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
    @gateway = WepayRails::Payments::Gateway.new(TEST_ACCESS_TOKEN)
  end

  def teardown
    # delete any test accounts that were created
    @gateway.find_account.each {|acct| @gateway.delete_account(acct[:account_id]) if acct.kind_of?(Hash) && acct[:account_id].present?}
    delete_wepay_config_file
  end

  test "should return errors from WePay when using invalid access token" do
    @gateway = WepayRails::Payments::Gateway.new("notAnAccessToken")
    @response = @gateway.create_account({
        :name => "Example Account",
        :description => "This is just an example WePay account."
    })

    assert_not_nil @response[:error]
    assert_nil @response[:account_id]
  end

  test "should create new WePay account" do
    @response = @gateway.create_account({
        :name => "Example Account",
        :description => "This is just an example WePay account."
    })

    assert_not_nil @response[:account_id]
    assert_not_nil @response[:account_uri]
  end

  test "should get WePay account" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account."
    })[:account_id]
    @response = @gateway.get_account(@account)

    assert_not_nil @response[:name]
    assert_equal "Example Account", @response[:name]
    assert_equal "This is just an example WePay account.", @response[:description]
  end

  test "should find WePay account by reference id or name" do
    sleep rand(4) # force Ruby to wait to avoid latency issues
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account.",
       :reference_id => "wepayrailstestaccount12345"
    })[:account_id]
    sleep rand(4)
    @response = @gateway.find_account(:reference_id => "wepayrailstestaccount12345")

    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"
    assert_equal 1, @response.length
    assert_equal "Example Account", @response.first[:name]
  end

  test "should find all WePay accounts for current authorized user" do
    # force Ruby to wait using sleep to avoid latency issues
    # using rand helps avoid simultaneous connections, but not perfectly

    sleep rand(4)
    @response = @gateway.find_account
    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"

    @count = @response.length
    sleep rand(4)
    @gateway.create_account({
         :name => "Example Account",
         :description => "This is just an example WePay account."
     })
    sleep 2 + rand(4)
    @response = @gateway.find_account

    assert_equal @count + 1, @response.length
    assert_equal "Example Account", @response.first[:name]
  end

  test "should modify WePay account" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account."
    })[:account_id]
    @response = @gateway.modify_account(@account, {
        :name => "This is a new Name!",
        :description => "This is a new description!"
    })

    assert_not_nil @response[:account_id]
    assert_equal "This is a new Name!", @response[:name]
    assert_equal "This is a new description!", @response[:description]
  end

  test "should get current balance of WePay account" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account."
    })[:account_id]
    @response = @gateway.get_account_balance(@account)

    assert_not_nil @response[:pending_balance]
    assert_not_nil @response[:available_balance]
    assert_not_nil @response[:currency]
    assert_equal 0, @response[:available_balance]
  end

  test "should delete WePay account" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account."
    })[:account_id]
    @response = @gateway.delete_account(@account)

    assert_not_nil @response[:account_id]
    assert_equal @account, @response[:account_id]
  end
end
