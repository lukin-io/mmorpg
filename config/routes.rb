require "sidekiq/web"

Rails.application.routes.draw do
  # NOTE: Devise 4.9.x generates deprecation warnings about hash arguments in Rails 8.2
  # This is a known Devise issue and will be fixed in Devise 4.10+
  # See: https://github.com/heartcombo/devise/issues/5644
  devise_for :users

  mount ActionCable.server => "/cable"

  authenticate :user, ->(user) { user.has_role?(:admin) } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # Public battle logs (shareable URLs)
  get "logs/:share_token", to: "public_battle_logs#show", as: :public_battle_log

  resource :session_ping, only: :create
  get "pinfo.cgi", to: "public_profiles#pinfo", as: :pinfo
  resources :profiles, only: :show, controller: :public_profiles, param: :profile_name

  # Character Stats & Skills Allocation
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

  resources :chat_channels, only: [:index, :show] do
    resources :chat_messages, only: :create
  end

  resources :friendships, only: [:index, :create, :update, :destroy]
  resources :mail_messages, only: [:index, :show, :new, :create]
  resources :chat_reports, only: [:index, :create]
  resources :ignore_list_entries, only: [:index, :create, :destroy]
  resources :group_listings
  resources :social_hubs, only: [:index, :show]

  resources :guilds do
    resources :guild_applications, only: :create
    resources :guild_bank_entries, only: [:index, :create]
    resources :guild_bulletins, only: [:index, :create]
    resources :guild_ranks, only: [:index, :update, :create]
  end
  resources :guild_applications, only: :update
  resources :guild_memberships, only: [:update, :destroy]
  resources :guild_bulletins, only: :destroy
  resources :guild_ranks, only: :destroy

  resources :clans do
    resources :clan_applications, only: [:create, :update], path: "applications"
    resources :clan_message_board_posts, only: [:create, :update, :destroy], path: "messages"
    resources :clan_treasury_transactions, only: :create, path: "treasury"
    resources :clan_stronghold_upgrades, only: [:create, :update], path: "stronghold_upgrades"
    resources :clan_research_projects, only: [:create, :update], path: "research_projects"
    resources :clan_quests, only: [:create, :update], path: "quests"
    resource :clan_role_permissions, only: :update, path: "role_permissions"
    resources :clan_wars, only: :create
  end
  resources :clan_memberships, only: [:update, :destroy]

  resources :auction_listings do
    resources :auction_bids, only: :create
  end
  resources :marketplace_kiosks, only: [:index, :create]
  resources :trade_sessions, only: [:create, :show, :update] do
    resources :trade_items, only: :create
  end
  resources :trade_items, only: :destroy

  resources :professions, only: :index do
    member do
      post :enroll
      post :reset_progress
    end
  end

  # Skill Trees & Abilities
  resources :skill_trees, only: [:index, :show] do
    member do
      post :unlock
    end
    collection do
      post :respec
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

  resources :achievements, only: [:index, :create]
  resources :housing_plots, only: [:index, :create, :update] do
    member do
      post :upgrade
      post :decorate
      delete "decorate/:decor_id", action: :remove_decor, as: :remove_decor
    end
  end
  resources :pet_companions, only: [:index, :create] do
    member do
      post :care
    end
  end
  resources :mounts, only: [:index, :create] do
    collection do
      post :unlock_slot
    end
    member do
      post :assign_to_slot
      post :summon
    end
  end
  resources :parties do
    member do
      post :ready_check
      post :leave
      post :promote
      post :disband
    end

    resources :party_invitations, only: :create
    resources :party_memberships, only: [:update, :destroy]
  end
  resources :party_invitations, only: :update
  # Arena System
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

  # Dungeons
  resources :dungeons, only: [:index, :show] do
    resources :instances, controller: "dungeon_instances", only: [:create, :show] do
      member do
        post :enter_encounter
        post :complete_encounter
        post :leave
      end
    end
  end
  resources :dungeon_instances, only: [:show] do
    member do
      post :enter_encounter
      post :complete_encounter
      post :leave
    end
  end

  # Inventory Management
  resource :inventory, only: [:show] do
    post :equip
    post :unequip
    post :use
    post :sort
  end
  resources :inventory_items, only: [:destroy], path: "inventory/items"

  # Equipment Enhancement
  resources :equipment_enhancements, only: [:index, :show] do
    member do
      post :enhance
      post :preview
    end
  end

  # Premium Store
  resources :premium_store, only: [:index, :show] do
    member do
      post :purchase
      post :gift
    end
  end

  # Marketplace Kiosks
  resources :marketplace_kiosks, only: [:show] do
    member do
      post :quick_buy
      post :quick_sell
    end
  end

  # Titles
  resources :titles, only: [:index] do
    member do
      post :equip
    end
    collection do
      delete :unequip
    end
  end

  resources :announcements, only: [:index, :create]

  resources :game_events, only: [:index, :show, :update]
  resources :leaderboards, only: [:index, :show] do
    post :recalculate, on: :member
  end
  resources :competition_brackets, only: [:show, :update]
  resources :quests, only: [:index, :show] do
    member do
      post :accept
      post :complete
      post :advance_story
    end
    collection do
      post :daily
    end
  end
  resources :spawn_schedules, only: [:index, :create, :update]
  resources :npc_reports, only: [:new, :create]
  resources :combat_logs, only: :show

  # Turn-Based Combat (Unified PvE/PvP/Arena)
  resources :battles, only: [:show] do
    member do
      post :submit_turn
      post :flee
      post :surrender
    end
  end

  namespace :moderation do
    resources :reports, only: [:new, :create]
    resources :tickets, only: [] do
      resources :appeals, only: [:new, :create]
    end
    resource :panel, only: :show
  end

  namespace :admin do
    namespace :moderation do
      resources :tickets, only: [:index, :show, :update] do
        resources :actions, only: :create
        resource :appeal, only: :update
      end
    end

    namespace :live_ops do
      resources :events, only: [:index, :create, :update]
    end

    resources :clan_moderations, only: [:index, :create]

    resource :gm_console, only: :show, controller: "gm_console" do
      post :spawn
      post :disable
      post :adjust_timers
      post :compensate
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Game World - Main gameplay area
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

  # PvE Combat
  resource :combat, only: :show, controller: "combat" do
    post :start
    post :action
    post :flee
    get :skills
  end

  # PvP Combat (Open World)
  resources :pvp_combat, only: [:show, :create] do
    collection do
      post :attack
      get :status
      post :toggle_pvp
    end
    member do
      post :action
      post :turn
      post :flee
      post :surrender
    end
  end

  # Resource Gathering
  resources :gathering, only: [:show] do
    member do
      post :harvest
    end
    collection do
      get :nodes
    end
  end

  # Dashboard - Admin/feature flag view
  resource :dashboard, only: :show, controller: "dashboard"

  # Root redirects to world (player's last location - map cell or city)
  # WorldController handles position persistence and renders appropriate view
  root "world#show"

  namespace :api do
    namespace :v1 do
      resources :fan_tools, only: :index
    end
  end
end
