class Wepay::IpnController < Wepay::ApplicationController
  def index

    checkout = wepay_gateway.lookup_checkout(params[:checkout_id])

    File.open('/tmp/wepay.log','a') {|f| f.write(checkout.inspect)}

    puts "*"*50
    puts @config.inspect
    puts "*"*50

    raise StandardError.new("Your wepay.yml isn't being read for some reason") if @config.blank?
    raise StandardError.new("A model needs to exist to trap the IPN messages from Wepay. Please create a model (eg. WepayCheckoutRecord) and set the class name in your wepay.yml, wepay_checkout_model directive") if @config[:wepay_checkout_model].blank?

    klass = @config[:wepay_checkout_model]
    record = klass.find_by_checkout_id(params[:checkout_id])

    if record.present?
      record.update_attributes(checkout)
    else
      model = klass.new
      model.save!
    end

    render :text => 'ok'
  end
end
