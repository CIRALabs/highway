Rails.application.routes.draw do
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new
  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  resources :voucher_requests, concerns: :active_scaffold
  resources :owners,   concerns: :active_scaffold
  resources :vouchers, concerns: :active_scaffold
  resources :devices,  concerns: :active_scaffold

  post '/requestvoucher', to: 'est#requestvoucher'

end
