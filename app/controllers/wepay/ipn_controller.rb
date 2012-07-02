class Wepay::IpnController < Wepay::ApplicationController
  def create

    record = WepayCheckoutRecord.find_by_checkout_id_and_security_token(params[:checkout_id],params[:security_token])

    if record.present?
      wepay_gateway = WepayRails::Payments::Gateway.new
      checkout = wepay_gateway.lookup_checkout(record.checkout_id)
      
      # remove unnecessary attributes
      checkout.delete_if {|k,v| !record.attributes.include? k.to_s}
      
      record.update_attributes(checkout)
      render :text => "ok"
    else
      raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]} and security_token #{params[:security_token]}")
    end

  end
end