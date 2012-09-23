module WepayRails
  module Helpers
    module ControllerHelpers

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
      def init_checkout(params, access_token=nil)
        wepay_gateway = WepayRails::Payments::Gateway.new(access_token)
        response      = wepay_gateway.perform_checkout(params)

        if response[:checkout_uri].blank?
          raise WepayRails::Exceptions::WepayCheckoutError.new("An error occurred: #{response.inspect}")
        end

        params.merge!({
            :access_token   => wepay_gateway.access_token,
            :checkout_id    => response[:checkout_id],
            :security_token => response[:security_token],
            :checkout_uri   => response[:checkout_uri]
        })
        
        params.delete_if {|k,v| !WepayCheckoutRecord.attribute_names.include? k.to_s}

        WepayCheckoutRecord.create(params)
      end

      def init_checkout_and_send_user_to_wepay(params, access_token=nil)
        record = init_checkout(params, access_token)
        redirect_to record.checkout_uri and return record
      end
      
      #Parameter				Required	Format			Description
      #account_id				Yes		Number			The WePay account where the money will go when you use this pre-approval to execute a payment.
      #amount					No		Number			The amount for the pre-approval. The API application can charge up to this amount every period.
      #short_description			Yes		String			A short description of what the payer is paying for.
      #period					Yes		String			Can be: hourly, daily, weekly, biweekly, monthly, bimonthly, quarterly, yearly, or once. The API application can charge the payer every period.
      #reference_id				No		String			The reference id of the pre-approval. Can be any string, but must be unique for the application/user pair.
      #app_fee					No		Number			The application fee that will go to the API application's account.
      #fee_payer				No		String			Who will pay the WePay fees and app fees (if set). Can be payee or payer. Defaults to payer.
      #redirect_uri				No		String			The uri the payer will be redirected to after approving the pre-approval.
      #callback_uri				No		String			The uri that any instant payment notifications will be sent to. Needs to be a full uri (ex https://www.wepay.com ) and must NOT be localhost or 127.0.0.1 or include wepay.com. Max 2083 										chars.
      #require_shipping			No		Boolean			Defaults to false. If set to true then the payer will be require to enter their shipping address when they approve the pre-approval.
      #shipping_fee				No		Number			The dollar amount of shipping fees that will be charged.
      #charge_tax				No		Boolean			Defaults to false. If set to true then any applicable taxes will be charged.
      #payer_email_message			No		String			A short message that will be included in the payment confirmation email to the payer.
      #payee_email_message			No		String			A short message that will be included in the payment confirmation email to the payee.
      #long_description			No		String			An optional longer description of what the payer is paying for.
      #frequency				No		Number			How often per period the API application can charge the payer.
      #start_time				No		Number or String	When the API application can start charging the payer. Can be a unix_timestamp or a parse-able date-time.
      #end_time				No		Number or String	The last time the API application can charge the payer. Can be a unix_timestamp or a parse-able date-time. The default value is five (5) years from the preapproval creation time.
      #auto_recur				No		Boolean			Set to true if you want the payments to automatically execute every period. Useful for subscription use cases. Default value is false. Only the following periods are allowed if you set 										auto_recur to true: Weekly, Biweekly, Monthly, Quarterly, Yearly
      #mode					No		String			What mode the pre-approval confirmation flow will be displayed in. The options are 'iframe' or 'regular'. Choose 'iframe' if this is an iframe pre-approval. Mode defaults to 'regular'.
      #prefill_info				No		Object			A JSON object that lets you pre fill certain fields in the pre-approval flow. Allowed fields are 'name', 'email', 'phone_number', 'address', 'city', 'state', 'zip', Pass the prefill-info 										as a JSON object like so: {"name":"Bill Clerico","phone_number":"855-469-3729"}
      #funding_sources				No		String			What funding sources you want to accept for this checkout. Options are: "bank,cc" to accept both bank and cc payments, "cc" to accept just credit card payments, and "bank" to accept just 										bank payments.
      
      
      def init_preapproval(params, access_token=nil)
        wepay_gateway = WepayRails::Payments::Gateway.new(access_token)
        response      = wepay_gateway.perform_preapproval(params)

        if response[:preapproval_uri].blank?
          raise WepayRails::Exceptions::WepayPreapprovalError.new("An error occurred: #{response.inspect}")
        end

        params.merge!({
            :access_token   => wepay_gateway.access_token,
            :preapproval_id    => response[:preapproval_id],
            :security_token => response[:security_token],
            :preapproval_uri   => response[:preapproval_uri]
        })
        
        params.delete_if {|k,v| !WepayCheckoutRecord.attribute_names.include? k.to_s}

        WepayCheckoutRecord.create(params)
      end
      
      def init_preapproval_and_send_user_to_wepay(params, access_token=nil)
        record = init_preapproval(params, access_token)
        redirect_to record.preapproval_uri and return record
      end
      
      def init_charge(params, access_token=nil)
        wepay_gateway = WepayRails::Payments::Gateway.new(access_token)
        response      = wepay_gateway.perform_charge(params)

        params.merge!({
            :access_token   => wepay_gateway.access_token,
            :preapproval_id => response[:preapproval_id],
            :checkout_id    => response[:checkout_id],
            :security_token => response[:security_token],
        })
        
        params.delete_if {|k,v| !WepayCheckoutRecord.attribute_names.include? k.to_s}

        WepayCheckoutRecord.create(params)
      end

      def init_charge_and_return_ipn(params, access_token=nil)
        record = init_charge(params, access_token)
        redirect_to charge_success_url and return record
      end
    

    end
  end
end
