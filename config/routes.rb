Rails.application.routes.draw do

  if $ADMININTERFACE or Rails.env == 'test'
  devise_for :admins
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new
  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  resources :voucher_requests, concerns: :active_scaffold
  resources :owners,   concerns: :active_scaffold
  resources :vouchers, concerns: :active_scaffold
  resources :devices,  concerns: :active_scaffold
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher',  to: 'est#requestvoucher'
  post '/.well-known/est/requestauditlog', to: 'est#requestauditlog'

  # EST processing of smartpledge URLs
  post '/.well-known/est/smartpledge',  to: 'smartpledge#enroll'
  post '/smartpledge/enroll',           to: 'smartpledge#enroll'

  resources :status,  :only => [:index ]
  resources :version, :only => [:index ]

end
