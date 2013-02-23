class Ipn < ActiveRecord::Base
  has_many :wepay_checkout_records
  
end