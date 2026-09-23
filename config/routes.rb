Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "help", to: "static_pages#help"

  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resource :profile, only: [ :show, :edit, :update ], controller: "users"

  resources :password_resets, param: :token, only: [ :new, :create, :edit, :update ]

  resources :recipes do
    resources :comments, only: [ :create, :edit, :update, :destroy ], shallow: true
    resource :favorite, only: [ :create, :destroy ]
  end
  resources :ratings, only: [ :create ]

  get "gacha", to: "gacha#show"
  post "gacha", to: "gacha#create"
  post "gacha/seven", to: "gacha#seven"

  resources :monsters, only: [ :index, :show ]

  get "user_monsters", to: "user_monsters#index", as: :user_monsters
  delete "user_monsters", to: "user_monsters#destroy"

  resource :battle, only: [ :show ], controller: "battles"
  post "battle_results", to: "battle_results#create"

  root "recipes#index"
end
