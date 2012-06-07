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

      def add_config_defaults(erb=false, client_id="124457", client_secret="f66b540433")
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
  TEST_ACCESS_TOKEN = "cce28dc50618c135005cc588fe3a8b8cdb35acc92a54209d6a0f4408e61be801"

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
end
