Rails.application.routes.draw do 
  namespace :wepay do
    resources :ipn
    resources :authorize
  end
end
