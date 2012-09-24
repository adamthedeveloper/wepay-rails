class Wepay::ChargeController < Wepay::ApplicationController
  include WepayRails::Payments
  
  def index
    record = WepayCheckoutRecord.find_by_checkout_id_and_security_token(params[:checkout_id],params[:security_token])

      if record.present?
          wepay_gateway = WepayRails::Payments::Gateway.new( record.access_token )
          charge = wepay_gateway.lookup_preapproval(record.preapproval_id)

          # remove unnecessary attributes
          charge.delete_if {|k,v| !record.attributes.include? k.to_s}

          record.update_attributes(charge)
          redirect_to "#{wepay_gateway.configuration[:after_charge_redirect_uri]}?checkout_id=#{params[:checkout_id]}"
      else
          raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]} and security_token #{params[:security_token]}")
      end
  end
  
  def success
    response = WepayCheckoutRecord.find(:last)
    wepay_gateway = WepayRails::Payments::Gateway.new( response.access_token )
    charge = wepay_gateway.lookup_checkout(response.checkout_id)

    response.update_attributes(charge)
    logger.info params
    render :text => "Wepay charge OK from #{response.payer_email} with Checkout ID # #{response.checkout_id} from the Pre-approval ID # #{response.preapproval_id}."
  end
  
  def new
    # The following is from the Wepay API sample checkout call
    # create the checkout
    charge_params = {
        :amount             => '50.00', 
        :short_description  => 'A Checkout on the Wepay PreApproval.', 
        :type               => 'GOODS',
        :preapproval_id     => xxxxx # To test, be sure to manually add the preapproval_id from the preapproval response which will skip having to go to Wepay to add CC info.
    }
    # Finally, send user to charge on the preapproval.
    init_charge_and_return_success(charge_params)
  end
end