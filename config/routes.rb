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
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
