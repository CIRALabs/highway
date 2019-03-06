Rails.application.routes.draw do

  if $ADMININTERFACE or Rails.env == 'test'
  devise_for :admins
  resources :voucher_requests
  resources :owners
  resources :vouchers
  resources :devices
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher',  to: 'est#requestvoucher'
  post '/.well-known/est/requestauditlog', to: 'est#requestauditlog'

  resources :status,  :only => [:index ]
  resources :version, :only => [:index ]

end
