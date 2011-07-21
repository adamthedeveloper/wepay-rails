module WepayRails
  module Helpers
    module ControllerHelpers
      # Get the auth code for the customer
      # arguments are the redirect_uri and an array of permissions that your application needs
      # ex. ['manage_accounts','collect_payments','view_balance','view_user']
      def auth_code_url(redirect_uri, permissions)
        params = {
            :client_id => @config[:client_id],
            :redirect_uri => redirect_uri,
            :scope => permissions.join(',')
        }

        query = params.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/v2/oauth2/authorize?#{query}"
      end

      def token_url(redirect_uri)
        params = config_params(redirect_uri)

        query = params.map do |k, v|
          "#{k.to_s}=#{v}"
        end.join('&')

        "#{@base_uri}/v2/oauth2/authorize?#{query}"
      end

      def config_params(redirect_uri)
        {
            :client_id => @config[:client_id],
            :redirect_uri => redirect_uri,
            :client_secret => @config[:client_secret],

        }
      end

      def redirect_to_wepay_for_auth(redirect_uri, scope)
        redirect_to gateway.auth_code_url(redirect_uri, scope)
      end

      def redirect_to_wepay_for_token(redirect_uri)
        redirect_to gateway.token_url(redirect_uri)
      end

      def gateway
        @gateway ||= WepayRails::Payments::Gateway.new
      end

      # Auth code is the code that we store in the model
      def wepay_auth_code=(auth_code)
        @wepay_auth_code = auth_code
      end

      # Auth code is the code that we store in the model
      def wepay_auth_code
        @wepay_auth_code
      end

      def wepay_auth_header
        {'Authorization' => "Bearer: #{wepay_auth_code}"}
      end

      def wepay_user
        response = self.class.get("/v2/user", {:headers => wepay_auth_header})
        JSON.parse(response)
      end

      # From https://stage.wepay.com/developer/tutorial/authorization
      # Request
      # https://stage.wepay.com/v2/oauth2/token
      # ?client_id=[your client id]
      # &redirect_uri=[your redirect uri ex. 'http://exampleapp.com/wepay']
      # &client_secret=[your client secret]
      # &code=[the code you got in step one]
      #
      # Response
      # {"user_id":"123456","access_token":"1337h4x0rzabcd12345","token_type":"BEARER"} Example
      def initialize_wepay_access_token(auth_code)
        logger.debug "WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - receiving #{auth_code}"
        File.open('/tmp/fugaze.log','a') {|f| f.write("WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - receiving #{auth_code}")}
        response = gateway.get("/v2/oauth2/token", config_params("http://www.example.com").merge(:code => auth_code))
        logger.debug "WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - response #{response.inspect}"
        File.open('/tmp/fugaze.log','a') {|f| f.write("WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - response #{response.inspect}")}
        raise unless response.present?
        logger.debug "WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - response is present"
        File.open('/tmp/fugaze.log','a') {|f| f.write("WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - response is present")}
        logger.debug response.inspect
        File.open('/tmp/fugaze.log','a') {|f| f.write(response.inspect)}
        json = JSON.parse(response.body)
        logger.debug "WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - json is #{json.inspect}"
        File.open('/tmp/fugaze.log','a') {|f| f.write("WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - json is #{json.inspect}")}
        wepay_access_token = json["access_token"]
        logger.debug "WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - wepay_access_token is #{wepay_access_token.inspect}"
        File.open('/tmp/fugaze.log','a') {|f| f.write("WepayRails::Helpers::ControllerHelpers#initialize_wepay_access_token - after call to wepay - wepay_access_token is #{wepay_access_token.inspect}")}
        raise unless wepay_access_token.present?
      end

      # Since we are saving the access token in the session,
      # ensure key uniqueness. Might be a good idea to have this
      # be a setting in the wepay.yml file.
      def unique_wepay_access_token_key
        :IODDR8856UUFG6788
      end

      # Access token is the OAUTH access token that is used for future
      # comunique
      def wepay_access_token=(value)
        session[unique_wepay_access_token_key] = value
      end

      # Access token is the OAUTH access token that is used for future
      # comunique
      def wepay_access_token
        session[unique_wepay_access_token_key]
      end

      def wepay_access_token_exists?
        @access_token_exists ||= wepay_access_token.present?
      end
    end
  end
end