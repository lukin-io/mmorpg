Rails.application.routes.draw do
  # Already implemented MVP Neverlands-based game-design routes.
  # These are the canonical player-facing routes for features already promoted
  # into doc/design.
  root "world#show"

  get "player/:name", to: "players#show", as: :player

  resources :characters, only: [] do
    member do
      get :stats
      patch :stats, action: :update_stats
      get :skills
      patch :skills, action: :update_skills
    end
  end

  resource :world, only: :show, controller: "world" do
    post :move
    post :enter
    post :enter_building
    post :interact_hotspot
    post :exit_location
  end

  resource :inventory, only: [:show] do
    post :equip
    post :unequip
    post :use
    post :sort
  end
  resources :inventory_items, only: [:destroy], path: "inventory/items"

  resources :arena, only: [:index], controller: "arena" do
    collection do
      get :lobby
    end
  end

  resources :arena_rooms, only: [:show] do
    resources :arena_applications, only: [:index, :create, :destroy] do
      member do
        post :accept
      end
    end
  end

  resources :arena_applications, only: [] do
    member do
      post :accept
      delete :cancel
    end
  end

  resources :arena_matches, only: [:show] do
    member do
      post :action
      post :claim_timeout
      post :finish
      get :log
    end
  end

  get "log/:id", to: "public_fight_logs#show", as: :public_fight_log
  post "fight/npc", to: "world_npc_fights#create", as: :world_npc_fights

  resources :chat_channels, only: [:show] do
    resources :chat_messages, only: :create
  end

  # Non-game related

  devise_for :users
  mount ActionCable.server => "/cable"
  resource :session_ping, only: :create
  get "up" => "rails/health#show", :as => :rails_health_check
end
