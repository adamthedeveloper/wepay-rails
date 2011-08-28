require 'active_record'
require 'helpers/model_helpers'
require 'helpers/controller_helpers'
module WepayRails

  module Exceptions
    class AccessTokenError < StandardError; end
    class ExpiredTokenError < StandardError; end
    class InitializeCheckoutError < StandardError; end
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

        yml = Rails.root.join('config', 'wepay.yml').to_s
        @config = YAML.load_file(yml)[Rails.env].symbolize_keys

        @scope = @config.delete(:scope)

        # Build the base uri
        # Default if there isn't a setting for version and/or api uri
        version = @config[:wepay_api_version].present? ? @config[:wepay_api_version] : "v2"
        api_uri = @config[:wepay_api_uri].present? ? @config[:wepay_api_uri] : "https://wepayapi.com"

        @base_uri = "#{api_uri}/#{version}"
      end

      def access_token(auth_code)
        @wepay_auth_code = auth_code
        query = {
          :client_id => @config[:client_id],
          :client_secret => @config[:client_secret],
          :redirect_uri => @config[:redirect_uri],
          :code => auth_code
        }
        response = self.class.get("#{@base_uri}/oauth2/token", :query => query)
        json = JSON.parse(response.body)

        if json.has_key?("error")
          if json.has_key?("error_description")
            raise WepayRails::Exceptions::ExpiredTokenError.new("You will need to get a new authorization code") if json["error_description"] == "the code has expired"
            raise WepayRails::Exceptions::AccessTokenError.new(json["error_description"])
          end
        end

        raise WepayRails::Exceptions::AccessTokenError.new("A problem occurred trying to get the access token: #{json.inspect}") unless json.has_key?("access_token")

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

        "#{@base_uri}/oauth2/authorize?#{query}"
      end

      def token_url
        query = @config.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/oauth2/authorize?#{query}"
      end

      def wepay_auth_header
        {'Authorization' => "Bearer: #{@wepay_access_token}"}
      end

      # Make a call to wepay to get the user info. This will only make one call
      # per request. Any subsequent calls to wepay_user will return the data
      # retrieved from the first call.
      def wepay_user
        user_api = lambda {|headers|
          File.open('/tmp/noisebytes.log','a') {|f|f.write("Base uri inside lambda is #{@base_uri}")}
          File.open('/tmp/noisebytes.log','a') {|f|f.write("Headers inside lambda is #{headers}")}
          response = self.class.get("#{@base_uri}/user", {:headers => headers})
          JSON.parse(response.body)
        }

        File.open('/tmp/noisebytes.log','a'){|f|f.write("User is #{user_api.call(wepay_auth_header)}")}

        @wepay_user ||= user_api.call(wepay_auth_header)
      end

      # Many of the settings you pass in here are already factored in from
      # the wepay.yml file and only need to be overridden if you insist on doing
      # so when this method is called. The following list of key values are pulled
      # in for you from your wepay.yml file:
      #
      # Note: @config is your wepay.yml as a Hash
      # :callback_uri     => @config[:ipn_callback_uri],
      # :redirect_uri     => @config[:checkout_redirect_uri],
      # :fee_payer        => @config[:fee_payer],
      # :type             => @config[:checkout_type],
      # :charge_tax       => @config[:charge_tax] ? 1 : 0,
      # :app_fee          => @config[:app_fee],
      # :auto_capture     => @config[:auto_capture] ? 1 : 0,
      # :require_shipping => @config[:require_shipping] ? 1 : 0,
      # :shipping_fee     => @config[:shipping_fee],
      # :charge_tax       => @config[:charge_tax],
      # :account_id       => wepay_user['account_id'] # wepay-rails goes and gets this for you, but you can override it if you want to.
      #
      #
      # params hash key values possibilities are:
      # Parameter:	Required:	Description:
      # :account_id	Yes	The unique ID of the account you want to create a checkout for.
      # :short_description	Yes	A short description of what is being paid for.
      # :long_description	No	A long description of what is being paid for.
      # :type	Yes	The the checkout type (one of the following: GOODS, SERVICE, DONATION, or PERSONAL)
      # :reference_id	No	The unique reference id of the checkout (set by the application in /checkout/create
      # :amount	Yes	The amount that the payer will pay.
      # :app_fee	No	The amount that the application will receive in fees.
      # :fee_payer	  No	Who will pay the fees (WePay's fees and any app fees). Set to "Payer" to charge fees to the person paying (Payer will pay amount + fees, payee will receive amount). Set to "Payee" to charge fees to the person receiving money (Payer will pay amount, Payee will receive amount - fees). Defaults to "Payer".
      # :redirect_uri 	No	The uri the payer will be redirected to after paying.
      # :callback_uri	  No	The uri that will receive any Instant Payment Notifications sent. Needs to be a full uri (ex https://www.wepay.com )
      # :auto_capture	No	A boolean value (0 or 1). Default is 1. If set to 0 then the payment will not automatically be released to the account and will be held by WePay in payment state 'reserved'. To release funds to the account you must call /checkout/capture
      # :require_shipping	No	A boolean value (0 or 1). If set to 1 then the payer will be asked to enter a shipping address when they pay. After payment you can retrieve this shipping address by calling /checkout
      # :shipping_fee	No	The amount that you want to charge for shipping.
      # :charge_tax	No	A boolean value (0 or 1). If set to 1 and the account has a relevant tax entry (see /account/set_tax), then tax will be charged.
      def perform_checkout(parms)
        defaults = {
            :callback_uri     => @config[:ipn_callback_uri],
            :redirect_uri     => @config[:checkout_redirect_uri],
            :fee_payer        => @config[:fee_payer],
            :type             => @config[:checkout_type],
            :charge_tax       => @config[:charge_tax] ? 1 : 0,
            :app_fee          => @config[:app_fee],
            :auto_capture     => @config[:auto_capture] ? 1 : 0,
            :require_shipping => @config[:require_shipping] ? 1 : 0,
            :shipping_fee     => @config[:shipping_fee],
            :charge_tax       => @config[:charge_tax],
            :account_id       => wepay_user['account_id']
        }.merge(parms)

        File.open('/tmp/noisebytes.log','a') {|f| f.write(defaults.inspect)}

        response = self.class.get("#{@base_uri}/checkout/create", {:headers => wepay_auth_header}.merge!(defaults))
        JSON.parse(response.body)
      end

    end

    include WepayRails::Exceptions
    include WepayRails::Helpers::ControllerHelpers
  end


  def self.included(base)
    base.extend WepayRails::Helpers::ModelHelpers
  end
end
ActiveRecord::Base.send(:include, WepayRails)