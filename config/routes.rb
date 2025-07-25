Rails.application.routes.draw do
  devise_for :users
  resources :characters

  resources :regions
  resources :items
  resources :inventories, only: [:index, :show]

  resources :guilds do
    resources :memberships, only: [:create, :destroy]
  end
  root "characters#index"
end
