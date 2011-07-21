require 'active_record'
module WepayRails
  module Payments
    require 'helpers/controller_helpers'
    class Gateway
      include HTTParty

      base_uri @base_uri

      attr_accessor :wepay_access_token, :wepay_auth_code

      def initialize(*args)
        yml = Rails.root.join('config', 'wepay.yml').to_s
        @config = YAML.load_file(yml)[Rails.env].symbolize_keys
        @base_uri = Rails.env.production? ? "https://api.wepay.com" : "https://stage.wepay.com"
      end

      def access_token(auth_code)
        @wepay_auth_code = auth_code
        File.open('/tmp/wepay-rails.log','a') {|f| f.write(auth_code)}
        File.open('/tmp/wepay-rails.log','a') {|f| f.write(@config.merge(:code => auth_code).inspect)}
        response = self.class.get("#{@base_uri}/v2/oauth2/token", @config.merge(:code => auth_code))
        json = JSON.parse(response.body)
        File.open('/tmp/wepay-rails.log','a') {|f| f.write(response.body)}
        File.open('/tmp/wepay-rails.log','a') {|f| f.write(json.inspect)}
        @wepay_access_token = json["access_token"]
      end

      # Get the auth code for the customer
      # arguments are the redirect_uri and an array of permissions that your application needs
      # ex. ['manage_accounts','collect_payments','view_balance','view_user']
      def auth_code_url(permissions)
        params = @config.merge(:scope => permissions.join(','))

        query = params.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/v2/oauth2/authorize?#{query}"
      end

      def token_url
        query = @config.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/v2/oauth2/authorize?#{query}"
      end

      def wepay_auth_header
        {'Authorization' => "Bearer: #{@wepay_access_token}"}
      end

      def wepay_user
        response = self.class.get("#{@base_uri}/v2/user", {:headers => wepay_auth_header})
        JSON.parse(response.body)
      end
    end

    include WepayRails::Helpers::ControllerHelpers
  end

  require 'helpers/model_helpers'
  def self.included(base)
    base.extend WepayRails::Helpers::ModelHelpers
  end
end
ActiveRecord::Base.send(:include, WepayRails)