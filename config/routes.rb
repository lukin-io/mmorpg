require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  authenticate :user, ->(user) { user.has_role?(:admin) } do
    mount Sidekiq::Web => "/sidekiq"
  end

  resource :session_ping, only: :create
  resources :profiles, only: :show, controller: :public_profiles, param: :profile_name

  resources :chat_channels, only: [:index, :show] do
    resources :chat_messages, only: :create
  end

  resources :friendships, only: [:index, :create, :update, :destroy]
  resources :mail_messages, only: [:index, :show, :new, :create]
  resources :chat_reports, only: [:index, :create]

  resources :guilds do
    resources :guild_applications, only: :create
  end
  resources :guild_applications, only: :update
  resources :guild_memberships, only: [:update, :destroy]

  resources :clans
  resources :clan_memberships, only: :destroy
  resources :clan_wars, only: :create

  resources :auction_listings do
    resources :auction_bids, only: :create
  end
  resources :marketplace_kiosks, only: [:index, :create]
  resources :trade_sessions, only: [:create, :show, :update]

  resources :professions, only: :index do
    post :update_progress, on: :member
  end
  resources :crafting_jobs, only: [:index, :create]

  resources :achievements, only: [:index, :create]
  resources :housing_plots, only: [:index, :create, :update]
  resources :pet_companions, only: [:index, :create]
  resources :mounts, only: [:index, :create]

  resources :announcements, only: [:index, :create]

  resources :game_events, only: [:index, :show, :update]
  resources :leaderboards, only: [:index, :show] do
    post :recalculate, on: :member
  end
  resources :competition_brackets, only: [:show, :update]

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
