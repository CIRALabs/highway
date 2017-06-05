Rails.application.routes.draw do
  resources :owners,   :active_scaffold => true
  resources :vouchers, :active_scaffold => true
  resources :devices,  :active_scaffold => true

  post '/requestvoucher', to: 'authentication#authenticate'

end
