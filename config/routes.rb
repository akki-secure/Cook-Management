Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

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

  namespace :api do
    namespace :v1 do
      post "auth", to: "sessions#create"
      resource :status, only: [ :show ], controller: "status"
      resources :monsters, only: [ :index ]
    end
  end

  root "recipes#index"
end
