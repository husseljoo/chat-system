Rails.application.routes.draw do
  resources :applications, param: :token do
    resources :chats, only: [:index, :show, :create], param: :number do
      resources :messages, only: [:index, :show], param: :number
    end
  end
  resources :chats
  resources :messages
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "all-chats", action: :all_chats, controller: :chats
  get "all-messages", action: :all_messages, controller: :messages
  get "api/search/", action: :search, controller: :messages

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
