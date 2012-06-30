class Wepay::CheckoutController < Wepay::ApplicationController
  def index
    record = WepayCheckoutRecord.find_by_checkout_id_and_security_token(params[:checkout_id],params[:security_token])

    if record.present?
      wepay_gateway = WepayRails::Payments::Gateway.new( record.access_token )
      checkout = wepay_gateway.lookup_checkout(record.checkout_id)
      
      # remove unnecessary attributes
      checkout.delete_if {|k,v| !record.attributes.include? k.to_s}
      
      record.update_attributes(checkout)
      redirect_to "#{wepay_gateway.configuration[:after_checkout_redirect_uri]}?checkout_id=#{params[:checkout_id]}"
    else
      raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]} and security_token #{params[:security_token]}")
    end
  end
end