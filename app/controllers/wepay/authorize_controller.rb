class Wepay::AuthorizeController < Wepay::ApplicationController
  def index
    ref_id = session[unique_wepay_auth_token_key]
    if WepayRails::Configuration.settings[:orm] == 'mongoid'
      wepayable = wepayable_class.where(wepayable_column => ref_id)[0]
    else
      wepayable = wepayable_class.all(:conditions => ["#{wepayable_column} = ?", ref_id])[0]
    end
    wepayable.update_attribute(wepayable_column.to_sym, params[:code])
    redirect_to session[:after_authorize_redirect_uri] if session[:after_authorize_redirect_uri]
    redirect_to WepayRails::Configuration.settings[:after_authorize_redirect_uri]
  rescue => e
    raise AuthorizationError.new("WepayRails was unable to find the record to save the auth code to. : #{e.message}") unless wepayable.present?
  end
end
