class Wepay::IpnController < Wepay::ApplicationController
  def index

    log = File.open('/tmp/ipn.log','a')

    record = WepayCheckoutRecord.find_by_checkout_id(params[:checkout_id])

    log.puts record.inspect

    if record.present?
      wepay_gateway.access_token(record.auth_code)
      checkout = wepay_gateway.lookup_checkout(record.checkout_id)
      log.puts checkout.inspect
      record.update_attributes(checkout)
    else
      raise StandardError.new("Wepay IPN: No record found for checkout_id #{params[:checkout_id]}")
    end

    render :text => 'ok'
  end
end
