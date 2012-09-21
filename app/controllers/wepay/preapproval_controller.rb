def index
      conds = {
            :security_token  => params[:security_token],
            :preapproval_id  => params[:preapproval_id],
          }

      record = WepayCheckoutRecord.where(conds).first
      
      if record.present?
        wepay_gateway = WepayRails::Payments::Gateway.new ( record.access_token )
        preapproval = wepay_gateway.lookup_preapproval(record.preapproval_id)

        #remove unneccesary attributes
        preapproval.delete_if {|k,v| !record.attributes.include? k.to_s}
        
        record.update_attributes(preapproval)
        redirect_to "#{wepay_gateway.configuration[:after_checkout_redirect_uri]}?preapproval_id=#{params[:preapproval_id]}"
      else
        raise StandardError.new("Wepay IPN: No record found for preapproval_id #{params[:preapproval_id]} and security_token #{params[:security_token]}")
      end
end