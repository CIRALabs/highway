Rails.application.routes.draw do
  resources :owners do
    as_routes
  end

  resources :vouchers do
    as_routes
  end

  resources :devices do
    as_routes
  end

end
