require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  authenticate :user, ->(user) { user.has_role?(:admin) } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resource :session_ping, only: :create

  resources :chat_channels, only: [:index, :show] do
    resources :chat_messages, only: :create
  end

  resources :friendships, only: [:index, :create, :update, :destroy]
  resources :mail_messages, only: [:index, :show, :new, :create]
  resources :chat_reports, only: [:index, :create]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#show"
end
