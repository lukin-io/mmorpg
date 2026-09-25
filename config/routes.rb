Rails.application.routes.draw do
  namespace :manage do
    root "dashboard#index"
    resources :world_cells
    resource :world_atlas, only: :show
    resources :tile_buildings
    resources :npc_templates
    resources :tile_npcs
    resources :cities
    resources :city_hotspots
    resources :audit_events, only: [:index, :show]
    resource :idle_tick, only: :show, controller: "idle_ticks" do
      post :arm
      post :disarm
      post :run_once
    end
    resource :catalog_activation, only: :create, controller: "catalog_activations"
    resource :world_population, only: :create, controller: "world_populations"
    resources :characters, only: [:index, :show] do
      member do
        post :inject_level
        post :grant_kit
        post :grant_item
        post :grant_currency
        post :grant_bot_kit
        post :remove_item
        post :toggle_inq
        post :upload_portrait
        patch :update_inventory_item
      end
    end
    resource :playable_region, only: :create, controller: "playable_regions"
    resources :unique_items, only: [:new, :create]
    resources :gift_boxes, only: [:index, :new, :create, :edit, :update] do
      member do
        post :toggle
      end
    end
    resources :world_fortresses, only: [:index, :edit, :update]
  end

  # Already implemented MVP Neverlands-based game-design routes.
  # These are the canonical player-facing routes for features already promoted
  # into doc/design.
  root "world#show"

  get "players/find", to: "players#find", as: :find_player
  get "player/:name", to: "players#show", as: :player
  get "settlement/:key", to: "settlements#show", as: :settlement
  post "ignore", to: "ignore_list_entries#create", as: :ignore_list_entry
  delete "ignore", to: "ignore_list_entries#destroy", as: :unignore_list_entry
  get "dress", to: "dress#show", as: :dress

  resources :characters, only: [] do
    member do
      get :stats
      patch :stats, action: :update_stats
      get :skills
      patch :skills, action: :update_skills
      get :perks
      patch :perks, action: :update_perks
      patch :portrait
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

  resource :world_map, only: :show, controller: "world_maps"
  post "world/claim_fortress", to: "world_landmarks#claim_fortress", as: :world_claim_fortress
  post "world/enter_dungeon", to: "world_landmarks#enter_dungeon", as: :world_enter_dungeon
  post "world/siege_battle", to: "world_siege_battles#create", as: :world_siege_battle
  post "world/party_invite", to: "world_parties#invite", as: :world_party_invite
  post "world/party_accept", to: "world_parties#accept", as: :world_party_accept
  post "world/party_leave", to: "world_parties#leave", as: :world_party_leave

  resource :clan, only: [:show, :create] do
    post :upgrade_building
    post :invite
    post :respond_invitation
    post :set_role
    post :membership
    post :treasury_lock
    post :treasury_transfer
    post :transfer_leadership
    post :dissolve
    post :alliance_propose
    post :alliance_accept
    post :alliance_break
  end
  get "character/timers", to: "character_timers#show", as: :character_timers

  get "world/locations/:key", to: "world_locations#show", as: :world_location
  post "world/locations/:key/features", to: "world_locations#open_feature", as: :world_location_feature
  post "world/locations/:key/descend", to: "world_locations#descend", as: :world_location_descend
  post "world/locations/:key/ascend", to: "world_locations#ascend", as: :world_location_ascend
  post "world/locations/:key/gallery_dig", to: "world_locations#gallery_dig", as: :world_location_gallery_dig
  post "world/locations/:key/exchange", to: "world_locations#exchange", as: :world_location_exchange
  post "world/encounter_check", to: "world_encounter_checks#create", as: :world_encounter_check
  post "world/assault", to: "world_assaults#create", as: :world_assault
  post "world/auto_hunt", to: "world_auto_hunts#create", as: :world_auto_hunt
  post "world/auto_gather", to: "world_auto_gathers#create", as: :world_auto_gather
  post "world/city_defense", to: "world_city_defenses#create", as: :world_city_defense
  post "world/obelisk", to: "world_obelisks#create", as: :world_obelisk

  resources :pets, only: [:index] do
    collection do
      post :equip
      post :level_up
      post :rename
      post :expedition
    end
  end

  resource :premium, only: [:show], controller: "premium" do
    post :buy
    post :claim_stipend
  end

  resource :season, only: [:show], controller: "seasons" do
    post :unlock_premium
    post :claim
    post :buy_offer
  end

  resource :wars, only: [:show], controller: "wars"


  resources :combat_interventions, only: %i[index create]

  resource :trade_hub, only: [:show], controller: "trade_hub" do
    post :buy_supply
    post :buy_scroll
    post :list_auction
    post :buy_auction
    post :cancel_auction
    post :create_exchange
    post :fill_exchange
    post :buy_premium_pass
    post :claim_premium_stipend
  end

  resource :inventory, only: [:show] do
    post :equip
    post :unequip
    post :unequip_all
    post :use
    post :buy_scroll
    post :sort
    post :save_equipment_set
    post :wear_equipment_set
    delete :delete_equipment_set
    post :transfer_item
    post :gift_item
    post :sell_to_player
    post :accept_trade
    post :cancel_trade
    post :transfer_money
    post :attune
    post :fuse_rune
  end
  resources :inventory_items, only: [:destroy], path: "inventory/items"

  resource :gifts, only: [:show], controller: "gifts" do
    post :buy
    post :open
    post :claim
    post :set_birthday
  end

  resource :shop, only: [:show], controller: "shop" do
    post :buy
    post :sell
  end

  get "city/buildings/:building_key", to: "city_buildings#show", as: :city_building
  post "city/buildings/:building_key/rest", to: "city_buildings#rest", as: :city_building_rest
  post "city/buildings/:building_key/craft", to: "city_buildings#craft", as: :city_building_craft
  post "city/buildings/:building_key/repair", to: "city_buildings#repair", as: :city_building_repair
  post "city/buildings/:building_key/recraft", to: "city_buildings#recraft", as: :city_building_recraft
  post "city/buildings/:building_key/sell", to: "city_buildings#sell", as: :city_building_sell
  post "city/buildings/:building_key/rent_stall", to: "city_buildings#rent_stall", as: :city_building_rent_stall
  post "city/buildings/:building_key/list_stall", to: "city_buildings#list_stall", as: :city_building_list_stall
  post "city/buildings/:building_key/buy_stall", to: "city_buildings#buy_stall", as: :city_building_buy_stall
  post "city/buildings/:building_key/buy_premium", to: "city_buildings#buy_premium", as: :city_building_buy_premium
  post "city/buildings/:building_key/topup_vm", to: "city_buildings#topup_vm", as: :city_building_topup_vm
  post "city/buildings/:building_key/traumatologist", to: "city_buildings#traumatologist", as: :city_building_traumatologist
  post "city/buildings/:building_key/bless", to: "city_buildings#bless", as: :city_building_bless
  post "city/buildings/:building_key/bank", to: "city_buildings#bank", as: :city_building_bank
  post "city/buildings/:building_key/bank_item", to: "city_buildings#bank_item", as: :city_building_bank_item
  post "city/buildings/:building_key/post", to: "city_buildings#post", as: :city_building_post
  post "city/buildings/:building_key/list_auction", to: "city_buildings#list_auction", as: :city_building_list_auction
  post "city/buildings/:building_key/buy_auction", to: "city_buildings#buy_auction", as: :city_building_buy_auction
  post "city/buildings/:building_key/numismatics", to: "city_buildings#numismatics", as: :city_building_numismatics
  post "city/buildings/:building_key/souvenir", to: "city_buildings#souvenir", as: :city_building_souvenir
  post "city/buildings/:building_key/obelisk", to: "city_buildings#obelisk", as: :city_building_obelisk
  post "city/buildings/:building_key/law", to: "city_buildings#law", as: :city_building_law
  resources :quests, only: [:index] do
    member do
      post :accept
      post :turn_in
    end
  end
  get "instances", to: "instances#index", as: :instances
  post "instances/:kind/:id/launch", to: "instances#launch", as: :launch_instance
  resource :activity, only: [:show], controller: "activity" do
    post :claim
  end
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
      post :action
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
  post "help/location", to: "location_helps#create", as: :location_help

  # Non-game related

  devise_for :users, controllers: {registrations: "user_registrations", sessions: "user_sessions"}
  mount ActionCable.server => "/cable"
  resource :session_ping, only: :create
  get "locale/:locale", to: "locales#update", as: :switch_locale
  get "up" => "rails/health#show", :as => :rails_health_check
end
