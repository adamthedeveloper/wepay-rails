class Wepay::IpnController < Wepay::ApplicationController
  def index

    record = WepayCheckoutRecord.find_by_checkout_id(params[:checkout_id])

    if record.present?
      wepay_gateway.access_token(record.auth_code)
      checkout = wepay_gateway.lookup_checkout(record.checkout_id)
      record.update_attributes(checkout)
      render :text => 'ok'
    else
      raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]}")
    end
  end
end