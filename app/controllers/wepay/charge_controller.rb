class Wepay::ChargeController < Wepay::ApplicationController
  def index
    conds = {
          :security_token  => params[:security_token],
          :preapproval_id => params[:preapproval_id],
          :checkout_id     => params[:checkout_id],
        }

        record = WepayCheckoutRecord.where(conds).first

        if record.present?
              wepay_gateway = WepayRails::Payments::Gateway.new( record.access_token )
              charge = wepay_gateway.lookup_preapproval(record.preapproval_id)

              # remove unnecessary attributes
              charge.delete_if {|k,v| !record.attributes.include? k.to_s}

              record.update_attributes(charge)
              redirect_to "#{wepay_gateway.configuration[:after_checkout_redirect_uri]}?checkout_id=#{params[:checkout_id]}"
            else
              raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]} and security_token #{params[:security_token]}")
            end
  end
end