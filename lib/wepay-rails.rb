require 'active_record'
require 'helpers/controller_helpers'
require 'api/account_methods'
require 'api/checkout_methods'
module WepayRails
  class Configuration
    @@wepayable_class = nil
    @@wepayable_column = nil
    @@settings = nil

    def self.init_conf(klass, column, settings)
      @@wepayable_class, @@wepayable_column = klass, column
      @@settings = settings
    end

    def self.wepayable_class
      @@wepayable_class
    end

    def self.wepayable_column
      @@wepayable_column
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
      klass, column = settings[:auth_code_location].split('.')
      Configuration.init_conf(eval(klass), column, settings)
    end
  end

  module Exceptions
    class AccessTokenError < StandardError; end
    class ExpiredTokenError < StandardError; end
    class InitializeCheckoutError < StandardError; end
    class AuthorizationError < StandardError; end
  end

  module Payments
    class Gateway
      include HTTParty

      base_uri @base_uri

      attr_accessor :wepay_access_token, :wepay_auth_code, :scope

      # Pass in the wepay access token that we got after the oauth handshake
      # and use it for ongoing comunique with Wepay.
      # This also relies heavily on there being a wepay.yml file in your
      # rails config directory - it must look like this:
      #
      #
      def initialize(*args)
        @wepay_access_token = args.first

        @wepay_config = WepayRails::Configuration.settings

        # Build the base uri
        # Default if there isn't a setting for version and/or api uri
        version = @wepay_config[:wepay_api_version].present? ? @wepay_config[:wepay_api_version] : "v2"
        api_uri = @wepay_config[:wepay_api_uri].present? ? @wepay_config[:wepay_api_uri] : "https://wepayapi.com"

        @base_uri = "#{api_uri}/#{version}"
      end

      def access_token(wepayable_object)
        w_column = WepayRails::Configuration.wepayable_column.to_s.to_sym
        auth_code = if wepayable_object.is_a?(String)
                      wepayable_object
                    elsif wepayable_object.respond_to?(w_column)
                      wepayable_object.send(w_column)
                    end

        unless auth_code.present?
          raise WepayRails::Exceptions::AccessTokenError.new("The argument, #{wepayable_object.inspect}, passed into the
          access_token method cannot be used to get an access token. It is neither a string,
          nor an object containing the auth_code column you specified in wepay.yml.")
        end

        params = {
          :client_id => @wepay_config[:client_id],
          :client_secret => @wepay_config[:client_secret],
          :redirect_uri => (@wepay_config[:redirect_uri].present? ? @wepay_config[:redirect_uri] : "#{@wepay_config[:root_callback_uri]}/wepay/authorize"),
          :code => auth_code
        }

        response = self.call("/oauth2/token", {:body => params})

        if response.has_key?("error")
          if response.has_key?("error_description")
            if ['invalid code parameter','the code has expired'].include?(response['error_description'])
              raise WepayRails::Exceptions::ExpiredTokenError.new("Token either expired or invalid: #{response["error_description"]}")
            end
            raise WepayRails::Exceptions::AccessTokenError.new(response["error_description"])
          end
        end

        raise WepayRails::Exceptions::AccessTokenError.new("A problem occurred trying to get the access token: #{response.inspect}") unless response.has_key?("access_token")

        @wepay_auth_code    = auth_code
        @wepay_access_token = response["access_token"]
      end

      # Get the auth code url that will be used to fetch the auth code for the customer
      # arguments are the redirect_uri and an array of permissions that your application needs
      # ex. ['manage_accounts','collect_payments','view_balance','view_user']
      def auth_code_url(params = {})
        params[:client_id]    ||= @wepay_config[:client_id]
        params[:redirect_uri] ||= (@wepay_config[:redirect_uri].present? ? @wepay_config[:redirect_uri] : "#{@wepay_config[:root_callback_uri]}/wepay/authorize")
        params[:scope]        ||= WepayRails::Configuration.settings[:scope].join(',')

        query = params.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/oauth2/authorize?#{query}"
      end

      def wepay_auth_header
        unless @wepay_access_token
          raise WepayRails::Exceptions::AccessTokenError.new("No access token available")
        end
        {'Authorization' => "Bearer: #{@wepay_access_token}"}
      end

      # Make a call to wepay to get the user info. This will only make one call
      # per request. Any subsequent calls to wepay_user will return the data
      # retrieved from the first call.
      def wepay_user
        @wepay_user ||= self.call("/user")
      end

      def call(api_path, params={})
        response = self.class.post("#{@base_uri}#{api_path}", {:headers => wepay_auth_header}.merge!(params))
        JSON.parse(response.body)
      end

      include WepayRails::Api::CheckoutMethods
      include WepayRails::Api::AccountMethods
    end

    include WepayRails::Exceptions
    include WepayRails::Helpers::ControllerHelpers
  end

end
