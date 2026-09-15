Rails.application.routes.draw do
  post "city/buildings/:building_key/purchase", to: "city_buildings#purchase", as: :hospital_purchase
  get "character_vitals", to: "character_vitals#show"
  get "medical_care", to: "medical_care#show"
  post "medical_care/treat", to: "medical_care#create", as: :treat_injury
  post "medical_care/:id/accept", to: "medical_care#accept", as: :accept_injury_treatment
  post "medical_care/:id/decline", to: "medical_care#decline", as: :decline_injury_treatment

  namespace :manage do
    root "dashboard#index"
    resources :world_cells
    resources :tile_buildings
    resources :npc_templates
    resources :tile_npcs
    resources :cities
    resources :city_hotspots
    resources :audit_events, only: [:index, :show]
  end

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
  resources :character_licenses, only: :index, path: "character/licenses"
  resource :merchant_qualification, only: [], controller: "merchant_qualifications" do
    post :accept
    post :pay
    post :complete
  end

  resource :world, only: :show, controller: "world" do
    get :players
    post :move
    post :enter_building
    post :perform_local_action
    post :interact_hotspot
  end

  get "world/locations/:key", to: "world_locations#show", as: :world_location
  post "world/locations/:key/features", to: "world_locations#open_feature", as: :world_location_feature
  post "world/encounter_check", to: "world_encounter_checks#create", as: :world_encounter_check

  resource :inventory, only: [:show] do
    post :equip
    post :unequip
    post :unequip_all
    post :use
    post :sort
    post :save_equipment_set
    post :wear_equipment_set
    delete :delete_equipment_set
    post :transfer_item
    post :gift_item
    post :sell_to_player
    post :transfer_money
  end
  resources :inventory_items, only: [:destroy], path: "inventory/items"
  resource :scroll_use, only: [:create], path: "inventory/scroll_use"
  resource :combat_status, only: [:create]

  resource :shop, only: [:show], controller: "shop" do
    post :buy
    post :sell
  end

  get "city/buildings/:building_key", to: "city_buildings#show", as: :city_building
  resource :airship, only: %i[show create] do
    post :disembark
  end

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
      post :confirm_duel
      delete :refuse_duel
      post :action
      post :switch_opponent
      post :claim_timeout
      post :finish
      get :log
    end
  end

  get "log/:id", to: "public_fight_logs#show", as: :public_fight_log
  post "world/context", to: "world_context_actions#create", as: :world_context_action

  resources :chat_channels, only: [:show] do
    resources :chat_messages, only: :create
  end
  get "chat/local", to: "chat_channels#local", as: :local_chat
  post "chat/local", to: "chat_messages#create"

  # Non-game related

  devise_for :users, controllers: {registrations: "user_registrations", sessions: "user_sessions"}
  mount ActionCable.server => "/cable"
  resource :session_ping, only: :create
  get "up" => "rails/health#show", :as => :rails_health_check
end
