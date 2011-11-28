require 'active_record'
require 'helpers/controller_helpers'
require 'api/checkout_methods'
module WepayRails
  class Configuration
    @@settings = nil

    def self.init_conf(settings)
      @@settings = settings
    end

    def self.settings
      @@settings
    end
  end

  class Engine < Rails::Engine
    # Initializers
    initializer "WepayRails.initialize_wepay_rails" do |app|
      yml = Rails.root.join('config', 'wepay.yml').to_s
      settings = YAML.load_file(yml)[Rails.env].symbolize_keys
      Configuration.init_conf(settings)
    end
  end

  module Exceptions
    class AccessTokenError < StandardError; end
    class ExpiredTokenError < StandardError; end
    class InitializeCheckoutError < StandardError; end
    class AuthorizationError < StandardError; end
    class WepayCheckoutError < StandardError; end
  end

  module Payments
    class Gateway
      include HTTParty

      base_uri @base_uri

      attr_accessor :access_token

      # Pass in the wepay access token that we got after the oauth handshake
      # and use it for ongoing comunique with Wepay.
      # This also relies heavily on there being a wepay.yml file in your
      # rails config directory - it must look like this:
      def initialize(*args)
        @wepay_config = WepayRails::Configuration.settings
        @access_token = args.first || @wepay_config[:access_token]
        @base_uri     = @wepay_config[:wepay_api_uri] || "https://www.wepay.com/v2"
      end

      # Fetch the access token from wepay for the auth code
      def get_access_token(auth_code, redirect_uri)

        params = {
          :client_id     => @wepay_config[:client_id],
          :client_secret => @wepay_config[:client_secret],
          :redirect_uri  => redirect_uri,
          :code          => auth_code
        }

        response = self.class.post("#{@base_uri}/oauth2/token", {:body => params})
        json = JSON.parse(response.body)

        if json.has_key?("error")
          if json.has_key?("error_description")
            if ['invalid code parameter','the code has expired','this access_token has been revoked'].include?(json['error_description'])
              raise WepayRails::Exceptions::ExpiredTokenError.new("Token either expired, revoked or invalid: #{json["error_description"]}")
            end
            raise WepayRails::Exceptions::AccessTokenError.new(json["error_description"])
          end
        end

        raise WepayRails::Exceptions::AccessTokenError.new("A problem occurred trying to get the access token: #{json.inspect}") unless json.has_key?("access_token")

        @access_token = json["access_token"]
      end

      # Get the auth code url that will be used to fetch the auth code for the customer
      # arguments are the redirect_uri and an array of permissions that your application needs
      # ex. ['manage_accounts','collect_payments','view_balance','view_user']
      def auth_code_url(redirect_uri, params = {})
        params[:client_id]    ||= @wepay_config[:client_id]
        params[:scope]        ||= @wepay_config[:scope].join(',')
        params[:redirect_uri]   = redirect_uri

        query = params.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/oauth2/authorize?#{query}"
      end

      def wepay_auth_header
        unless @access_token
          raise WepayRails::Exceptions::AccessTokenError.new("No access token available")
        end
        {'Authorization' => "Bearer: #{@access_token}"}
      end

      def configuration
        @wepay_config
      end

      def call_api(api_path, params={})
        response = self.class.post("#{@base_uri}#{api_path}", {:headers => wepay_auth_header}.merge!({:body => params}))
        JSON.parse(response.body)
      end

      include WepayRails::Api::CheckoutMethods
    end

    include WepayRails::Exceptions
    include WepayRails::Helpers::ControllerHelpers
  end

end
