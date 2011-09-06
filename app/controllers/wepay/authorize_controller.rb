class Wepay::AuthorizeController < Wepay::ApplicationController
  def index
    #ref_id, code = if params[:refID].include?('?')
    #                 parts = params[:refID].split('?')
    #                 key,val = parts[1].split('=')
    #                 [parts[0], (key == 'code' ? val : '')]
    #               else
    #                 [params[:refID], params[:code]]
    #               end
    ref_id = session[unique_wepay_auth_token_key]
    wepayable = wepayable_class.all(:conditions => ["#{wepayable_column} = ?", ref_id])[0]
    wepayable.update_attribute(wepayable_column.to_sym, params[:code])
    redirect_to WepayRails::Configuration.settings[:after_authorize_redirect_uri]
  rescue => e
    raise AuthorizationError.new("WepayRails was unable to find the record to save the auth code to. : #{e.message}") unless wepayable.present?


  end
end