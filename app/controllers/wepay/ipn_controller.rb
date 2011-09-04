class Wepay::IpnController < Wepay::ApplicationController
  def index

    wepay_gateway

    log = File.open('/tmp/ipn.log','a')

    log.puts "*"*50
    log.puts @config.inspect
    log.puts "*"*50

    unless @config
      raise StandardError.new("Your wepay.yml isn't being read for some reason")
    end

    unless  @config[:wepay_checkout_model]
      raise StandardError.new("A model needs to exist to trap the IPN messages from Wepay. Please create a model (eg. WepayCheckoutRecord) and set the class name in your wepay.yml, wepay_checkout_model directive")
    end

    klass = @config[:wepay_checkout_model]
    record = klass.find_by_checkout_id(params[:checkout_id])

    log.puts record.inspect


    if record.present?
      wepay_gateway.access_token(record.auth_code)
      checkout = wepay_gateway.lookup_checkout(record.checkout_id)
      log.puts checkout.inspect
      record.update_attributes(checkout)
    else
      model = klass.new
      model.save!
    end

    render :text => 'ok'
  end
end
