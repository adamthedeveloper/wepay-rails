class Wepay::ApplicationController < ApplicationController
  include WepayRails::Payments

  def wepayable_class
    WepayRails::Configuration.wepayable_class
  end

  def wepayable_column
    WepayRails::Configuration.wepayable_column
  end
end