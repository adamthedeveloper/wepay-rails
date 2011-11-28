class Wepay::AuthorizeController < Wepay::ApplicationController

  def index
    wepay_gateway = WepayRails::Payments::Gateway.new

    if params[:code].present?
      access_token = wepay_gateway.get_access_token(params[:code], redirect_uri)
      render :text => "Copy this access token, #{access_token} to the access_token directive in your wepay.yml"
    else
      # For security purposes, stop people from hitting this page and resetting the access_token.
      if wepay_gateway.configuration[:access_token].present?
        render :text => "You have already specified an access token in wepay.yml. If you wish to change it, please delete the current one and try again."
      else
        redirect_to wepay_gateway.auth_code_url redirect_uri
      end
    end
  end

  private
  def redirect_uri
    "#{WepayRails::Configuration.settings[:root_callback_uri]}/wepay/authorize"
  end
end