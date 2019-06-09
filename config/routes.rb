Rails.application.routes.draw do

  root to: static("index.html")
  get '/favicon.ico', to: static("favicon.ico")

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

  # EST processing of smarkaklink URLs
  post '/.well-known/est/smarkaklink',  to: 'smarkaklink#enroll'
  post '/smarkaklink/enroll',           to: 'smarkaklink#enroll'
  post '/shg-provision',                to: 'smarkaklink#provision'

  resources :status,  :only => [:index ]
  resources :version, :only => [:index ]

end
