class WepayCheckoutRecord < ActiveRecord::Base
  belongs_to :checkout
  belongs_to :preapproval
  belongs_to :ipn
  belongs_to :authorize
  attr_accessible :amount, 
                  :short_description, 
                  :access_token, 
                  :checkout_id, 
                  :security_token, 
                  :checkout_uri, 
                  :account_id, 
                  :currency, 
                  :fee_payer, 
                  :state, 
                  :redirect_uri, 
                  :auto_capture, 
                  :app_fee, 
                  :gross, 
                  :fee, 
                  :callback_uri, 
                  :tax, 
                  :payer_email, 
                  :payer_name, 
                  :mode, 
                  :preapproval_id, 
                  :preapproval_uri,
                  :reference_id,
                  :period, 
                  :frequency, 
                  :start_time, 
                  :end_time, 
                  :auto_recur, 
                  :create_time, 
                  :manage_uri
end