WepayRails::Engine.routes.draw do
  namespace :wepay do
    resources :ipn
  end
end