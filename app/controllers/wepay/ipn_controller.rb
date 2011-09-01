class Wepay::IpnController < Wepay::ApplicationController
  def index
    raise StandardError.new("A model needs to exist to trap the IPN messages from Wepay. Please create a model (eg. WepayCheckoutRecord) and set the class name in your wepay.yml, wepay_checkout_model directive") if @config[:wepay_checkout_model].blank?

    klass = @config[:wepay_checkout_model]
    record = klass.find_by_checkout_id(params[:checkout_id])

    if record.present?
      record.update_attributes(params)
    else
      model = klass.new
      model.save!
    end

    render :text => 'ok'
  end
end