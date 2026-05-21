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
      get :perks
      patch :perks, action: :update_perks
    end
  end

  resource :world, only: :show, controller: "world" do
    post :move
    post :enter
    post :enter_building
    post :interact_hotspot
    post :exit_location
    post :gather
    post :gather_resource
    post :interact
    post :dialogue_action
  end

  resources :gathering, only: [:show] do
    member do
      post :harvest
    end
    collection do
      get :nodes
    end
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
      post :spectate
      get :log
    end
  end

  resources :arena_seasons, only: [:index, :show]

  get "log/:id", to: "public_fight_logs#show", as: :public_fight_log
  post "fight/npc", to: "world_npc_fights#create", as: :world_npc_fights

  resources :chat_channels, only: [:index, :show] do
    resources :chat_messages, only: :create
  end

  resources :professions, only: :index do
    member do
      post :enroll
    end
  end

  resources :crafting_jobs, only: [:index, :create] do
    collection do
      post :preview
    end
  end
  resources :profession_tools, only: [] do
    post :repair, on: :member
  end

  # UNCLARIFIED YET

  # NOTE: Devise 4.9.x generates deprecation warnings about hash arguments in Rails 8.2
  # This is a known Devise issue and will be fixed in Devise 4.10+
  # See: https://github.com/heartcombo/devise/issues/5644
  devise_for :users

  mount ActionCable.server => "/cable"

  resource :session_ping, only: :create

  resources :ignore_list_entries, only: [:index, :create, :destroy]

  get "up" => "rails/health#show", :as => :rails_health_check
end
