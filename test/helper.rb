require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rails/all'
require 'rails/test_help'
require 'thor'
require 'webmock/minitest'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'wepay-rails'

module WepayRails
  class TestsHelper < Thor
    include Thor::Actions
    source_root File.expand_path(File.dirname(__FILE__))

    no_tasks do
      def create_wepay_config_file(erb=false, defaults=false)
        copy_file "../lib/generators/wepay_rails/install/templates/wepay.yml", "../config/wepay.yml#{'.erb' if erb}", verbose: false, force: true
        gsub_file "../config/wepay.yml.erb", "<your access token that you received when you went to http://your.domain.com/wepay/authorize>", "<%= 'abc' * 3 %>", verbose: false if erb
        add_config_defaults(erb) if defaults
      end

      def add_config_defaults(erb=false, client_id="168738", client_secret="8d701ad2ac")
        gsub_file "../config/wepay.yml#{'.erb' if erb}", "<your client id from wepay>", client_id, verbose: false
        gsub_file "../config/wepay.yml#{'.erb' if erb}", "<your client secret from wepay>", client_secret, verbose: false
      end

      def delete_wepay_config_file
        remove_file "../config/wepay.yml", verbose: false
        remove_file "../config/wepay.yml.erb", verbose: false
      end
    end
  end
end

class ActiveSupport::TestCase
  TEST_ACCESS_TOKEN = "1c69cebd40ababb0447700377dd7751bb645e874edac140f1ba0c35ad6e98c97"

  def wepay_gateway(token=TEST_ACCESS_TOKEN)
    @wepay_gateway ||= WepayRails::Payments::Gateway.new(token)
  end

  def helper
    @helper ||= WepayRails::TestsHelper.new
  end

  def create_wepay_config_file(erb=false, defaults=false)
    helper.create_wepay_config_file(erb, defaults)
  end

  def delete_wepay_config_file
    helper.delete_wepay_config_file
  end

  def initialize_wepay_config
    yml = "../config/wepay.yml"
    if File.exists?(yml)
      settings = YAML.load_file(yml)[Rails.env].symbolize_keys
    elsif File.exists?(yml+".erb")
      settings = YAML::load(ERB.new(IO.read(yml+".erb")).result)[Rails.env].symbolize_keys
    end
    WepayRails::Configuration.init_conf(settings)
  end

  # Stubs for API calls
  # Uncomment the next line to allow live API calls
  # WebMock.allow_net_connect!(:net_http_connect_on_start => true)

  def sample_account_response(options={})
	{ "account_id" => "12345",
	  "name" => "Example Account",
	  "description" => "This is just an example WePay account.",
	  "account_uri" => "https://stage.wepay.com/account/12345" }.merge(options).to_json
  end

  def sample_find_response(options={})
	[{ "account_id" => "12345",
	   "name" => "Custom Reference ID",
	   "description" => "This is just an example WePay account.",
	   "reference_id" => "wepayrailstestaccount123",
	   "account_uri" => "https://stage.wepay.com/account/12345" }.merge(options)].to_json
  end

  def sample_balance_response(options={})
	{ "pending_balance" => "500",
	  "available_balance" => "500",
	  "currency" => "USD" }.merge(options).to_json
  end

  def sample_checkout_response(options={})
	{ "checkout_id" => "6789",
	  "checkout_uri" => "http://stage.wepay.com/api/checkout/6789" }.merge(options).to_json
  end
  
  def sample_preapproval_response(options={})
	{ "preapproval_id" => "6789",
	  "preapproval_uri" => "http://stage.wepay.com/api/preapproval/6789" }.merge(options).to_json
  end
end