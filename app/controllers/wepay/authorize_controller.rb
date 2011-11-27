require 'digest/sha2'
class Wepay::AuthorizeController < Wepay::ApplicationController

  def index
    wepay_gateway = WepayRails::Payments::Gateway.new

    if params[:code].present?
      access_token = wepay_gateway.get_access_token(params[:code], redirect_uri)
      render :text => "Copy this access token, #{access_token} to the access_token directive in your wepay.yml"
    else
      redirect_to wepay_gateway.auth_code_url redirect_uri
    end
  end

  private
  def redirect_uri
    "#{WepayRails::Configuration.settings[:root_callback_uri]}/wepay/authorize"
  end
end
