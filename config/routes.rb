Rails.application.routes.draw do
  resources :vouchers do
    as_routes
  end

  resources :devices do
    as_routes
  end

end
