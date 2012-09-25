class Wepay::IpnController < Wepay::ApplicationController
  include WepayRails::Payments
  def update
      record = WepayCheckoutRecord.find_by_checkout_id_and_security_token(params[:checkout_id],params[:security_token])

      if record.present?
        wepay_gateway = WepayRails::Payments::Gateway.new

        if record.checkout_id.present?
          checkout = wepay_gateway.lookup_checkout(record.checkout_id)
        else
          checkout = wepay_gateway.lookup_preapproval(record.preapproval_id)
        end
        checkout.delete_if {|k,v| !record.attributes.include? k.to_s}
        record.update_attributes(checkout)
        render :text => "ok"
      else
        raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]} and security_token #{params[:security_token]}")
      end

    end
end