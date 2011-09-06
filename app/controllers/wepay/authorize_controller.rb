class Wepay::AuthorizeController < Wepay::ApplicationController
  def index
    ac_log = File.open('/tmp/authorize-contoller.log','a')

    ac_log.puts "params[refID]: #{params[:refID]}"
    ref_id, code = if params[:refID].include?('?')
      ac_log.puts "-Found the question mark"
                     parts = params[:refID].split('?')
      ac_log.puts "parts are now #{parts.inspect}"
                     key,val = parts[1].split('=')
      ac_log.puts "key, val are #{key}, #{val}"
                     [parts[0], (key == 'code' ? val : '')]
                   else
                     ac_log.puts "No question mark found in #{params[:refID]}"
                     [params[:refID], params[:code]]
                   end
    ac_log.puts "ref_id, code are #{ref_id}, #{code}"
    wepayable = wepayable_class.all(:conditions => ["#{wepayable_column} = ?", ref_id])[0]
    rescue => e
    raise AuthorizationError.new("WepayRails was unable to find the record to save the auth code to. : #{e.message}") unless wepayable.present?

    wepayable.update_attribute(wepayable_column.to_sym, code)

    redirect_to WepayRails::Configuration.settings[:after_authorize_redirect_uri]
  end
end