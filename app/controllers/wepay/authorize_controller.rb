class Wepay::AuthorizeController < Wepay::ApplicationController
  def index
    ref_id, code = if params[:refID].include?('?')
                     parts = query.split('?')
                     key,val = parts[1].split('=')
                     [parts[0], (key == 'code' ? val : '')]
                   else
                     [params[:refID], params[:code]]
                   end
    wepayable = wepayable_class.find(:conditions => ["#{wepayable_column} = ?", ref_id])
    rescue => e
    raise AuthorizationError.new("WepayRails was unable to find the record to save the auth code to. : #{e.message}") unless wepayable.present?

    wepayable.update_attribute(wepayable_column.to_sym, code)

    redirect_to WepayRails::Configuration.settings[:after_authorize_redirect_uri]
  end
end