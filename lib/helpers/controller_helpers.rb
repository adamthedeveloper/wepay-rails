module WepayRails
  module Helpers
    module ControllerHelpers

      def redirect_to_wepay_for_auth(scope)
        redirect_to gateway.auth_code_url(scope)
      end

      def redirect_to_wepay_for_token
        redirect_to gateway.token_url
      end

      def gateway
        @gateway ||= WepayRails::Payments::Gateway.new
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
        wepay_access_token = gateway.access_token(auth_code)
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