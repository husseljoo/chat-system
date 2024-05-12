Rails.application.routes.draw do
  resources :applications, param: :token do
    get "/chats", to: "chats#list_by_token"
    # resources :chats, only: [:index]
    # resources :chats, only: [:list_by_token]
  end
  resources :chats
  resources :messages
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "api/search/", action: :search, controller: :messages

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
