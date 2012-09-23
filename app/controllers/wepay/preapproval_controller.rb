class Wepay::PreapprovalController < Wepay::ApplicationController
  include WepayRails::Payments
  
  def index
        record = WepayCheckoutRecord.find_by_preapproval_id_and_security_token(params[:preapproval_id],params[:security_token])
        
        
        if record.present?
          wepay_gateway = WepayRails::Payments::Gateway.new ( record.access_token )
          preapproval = wepay_gateway.lookup_preapproval(record.preapproval_id)

          #remove unneccesary attributes
          preapproval.delete_if {|k,v| !record.attributes.include? k.to_s}
          
          record.update_attributes(preapproval)
          redirect_to "#{wepay_gateway.configuration[:after_checkout_redirect_uri]}?preapproval_id=#{params[:preapproval_id]}"
        else
          raise StandardError.new("Wepay IPN: No record found for preapproval_id #{params[:preapproval_id]} and security_token #{params[:security_token]}")
        end
  end
  
  def success
    response = WepayCheckoutRecord.find(:last)
    wepay_gateway = WepayRails::Payments::Gateway.new( response.access_token )
    charge = wepay_gateway.lookup_preapproval(response.preapproval_id)

    response.update_attributes(charge)
    logger.info params
    render :text => "PRE-APPROVAL OK from #{response.payer_email} with Pre-approval ID # #{response.preapproval_id}. You can use this Pre-approval Id# to run a charge at a later time."
  end
  
  def new
    # create the preapproval - This is TEST info
    preapproval_params = {
            :period               => 'once',
            :end_time             => '2013-12-25',
            :amount               => '50.00',
            :mode                 => 'regular',
            :short_description    => 'A Preapproval for MyApp.',
            :app_fee              => "10",
            :fee_payer            => 'payee',
            :payer_email_message  => "You just approved MyApp to charge you for a some money later. You have NOT been charged at this time!"
    }
    # Finally, send the user off to wepay for the preapproval
    init_preapproval_and_send_user_to_wepay(preapproval_params)
  end
end