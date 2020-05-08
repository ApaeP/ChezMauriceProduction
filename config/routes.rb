Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  resources :contacts
  resources :videos do
    member do
      post 'update_rank'
    end
  end
  get 'mentions-legales', to: 'pages#legal'
  # get 'a-propos', to: 'pages#infos'
  get 'realisations', to: 'videos#index'
  get 'contacter', to: 'pages#contact'

  # match "*all" => "application#cors_preflight_check", :constraints => { :method => "OPTIONS" }
    # match '*unmatched_route', :to => 'api/v1/api#route_options', via: [:options]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
