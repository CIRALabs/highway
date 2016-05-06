Rails.application.routes.draw do
  resources :devices do
    as_routes
  end

end
