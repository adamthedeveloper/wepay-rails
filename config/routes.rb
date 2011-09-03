WepayRails::Engine.routes.draw do |map|
  namespace :wepay do
    resources :ipn
  end
end
