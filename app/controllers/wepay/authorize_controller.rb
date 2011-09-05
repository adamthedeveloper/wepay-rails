class Wepay::AuthorizeController < Wepay::ApplicationController
  def index
    ref_id = params[:refID]
    wepayable = @@wepayable_class.find(:conditions => ["#{@@wepayable_column} = ?", ref_id])
    rescue => e
    raise AuthorizationError.new("WepayRails was unable to find the record to save the auth code to. : #{e.message}") unless wepayable.present?

    wepayable.update_attribute(@@wepayable_column.to_sym, params[:code])

    redirect_to WepayRails::Configuration.settings[:after_authorize_redirect_uri]
  end
end