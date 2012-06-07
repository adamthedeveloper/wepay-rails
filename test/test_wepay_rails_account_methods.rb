require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestWepayRailsAccountMethods < ActiveSupport::TestCase
  def setup
    create_wepay_config_file(false, true)
    initialize_wepay_config
    @gateway = WepayRails::Payments::Gateway.new(TEST_ACCESS_TOKEN)
    @accounts = []
  end

  def teardown
    @accounts.each {|account| @gateway.delete_account(account)} # delete test accounts that were created
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

    @accounts << @response[:account_id] # add account for later deletion
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

    @accounts << @account # add account for later deletion
  end

  test "should find WePay account by reference id or name" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account.",
       :reference_id => "wepayrailstestaccount12345"
    })[:account_id]
    @response = @gateway.find_account(:reference_id => "wepayrailstestaccount12345")

    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"
    assert_equal 1, @response.length
    assert_equal "Example Account", @response.first[:name]

    @accounts << @account # add account for later deletion
  end

  test "should find all WePay accounts for current authorized user" do
    # This test is a bit weird.  First we assert that the API call works and
    # returns an Array, which also gives us the current amount of accounts.
    # Then we create some test accounts, simultaneously adding their account_id
    # to the @accounts hash for later deletion, and assert that the new account
    # was indeed added to the user's list of accounts

    @response = @gateway.find_account
    assert @response.kind_of?(Array), "<Array> expected but was <#{@response.class}>"

    @count = @response.length
    3.times do
      @accounts << @gateway.create_account({
           :name => "Example Account",
           :description => "This is just an example WePay account."
       })[:account_id]
    end
    @response = @gateway.find_account

    assert_equal @count + 3, @response.length
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

    @accounts << @account # add account for later deletion
  end

  test "should delete WePay account" do
    @account = @gateway.create_account({
       :name => "Example Account",
       :description => "This is just an example WePay account."
    })[:account_id]
    @response = @gateway.delete_account(@account)

    assert_not_nil @response[:account_id]
    assert_equal @account, @response[:account_id]

    @accounts << @account # add account for later deletion
  end
end