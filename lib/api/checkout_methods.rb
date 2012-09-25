require 'digest/sha2'
module WepayRails
  module Api
    module CheckoutMethods
      # Many of the settings you pass in here are already factored in from
      # the wepay.yml file and only need to be overridden if you insist on doing
      # so when this method is called. The following list of key values are pulled
      # in for you from your wepay.yml file:
      #
      # Note: @wepay_config is your wepay.yml as a Hash
      # :callback_uri     => @wepay_config[:ipn_callback_uri],
      # :redirect_uri     => @wepay_config[:checkout_redirect_uri],
      # :fee_payer        => @wepay_config[:fee_payer],
      # :type             => @wepay_config[:checkout_type],
      # :charge_tax       => @wepay_config[:charge_tax] ? 1 : 0,
      # :app_fee          => @wepay_config[:app_fee],
      # :auto_capture     => @wepay_config[:auto_capture] ? 1 : 0,
      # :require_shipping => @wepay_config[:require_shipping] ? 1 : 0,
      # :shipping_fee     => @wepay_config[:shipping_fee],
      # :charge_tax       => @wepay_config[:charge_tax],
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
      def perform_checkout(params)
        security_token = Digest::SHA2.hexdigest("#{Rails.env.production? ? rand(4) : 1}#{Time.now.to_i}") # Make less random during tests
        
        # add the security token to any urls that were passed in from the app
        if params[:callback_uri]
          params[:callback_uri] = apply_security_token( params[:callback_uri], security_token )
        end
        
        if params[:redirect_uri]
          params[:redirect_uri] = apply_security_token( params[:redirect_uri], security_token )
        end
        
        defaults = {
            :callback_uri     => ipn_callback_uri(security_token),
            :redirect_uri     => checkout_redirect_uri(security_token),
            :fee_payer        => @wepay_config[:fee_payer],
            :type             => @wepay_config[:checkout_type],
            :charge_tax       => @wepay_config[:charge_tax] ? 1 : 0,
            :app_fee          => @wepay_config[:app_fee],
            :auto_capture     => @wepay_config[:auto_capture] ? 1 : 0,
            :require_shipping => @wepay_config[:require_shipping] ? 1 : 0,
            :shipping_fee     => @wepay_config[:shipping_fee],
            :account_id       => @wepay_config[:account_id]
        }.merge(params)

        resp = self.call_api("/checkout/create", defaults)
        resp.merge({:security_token => security_token})
      end

      def lookup_checkout(checkout_id)
        co = self.call_api("/checkout", {:checkout_id => checkout_id})
        co.delete(:type)
        co
      end
      
      def lookup_preapproval(preapproval_id)
        co = self.call_api("/preapproval", {:preapproval_id => preapproval_id})
        co.delete("type")
        co
      end

      def ipn_callback_uri(security_token)
        uri = if @wepay_config[:ipn_callback_uri].present?
                @wepay_config[:ipn_callback_uri]
              else
                "#{@wepay_config[:root_callback_uri]}/wepay/ipn"
              end
        apply_security_token(uri, security_token)
      end

      def checkout_redirect_uri(security_token)
        uri = if @wepay_config[:ipn_callback_uri].present?
                @wepay_config[:checkout_redirect_uri]
              else
                "#{@wepay_config[:root_callback_uri]}/wepay/checkout"
              end
        apply_security_token(uri, security_token)
      end

      def apply_security_token(uri, security_token)
        uri += (uri =~ /\?/ ? '&' : '?') + "security_token=#{security_token}"
      end
    end
  end
end
