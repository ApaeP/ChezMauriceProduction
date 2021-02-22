Rails.application.routes.draw do
  devise_for :users, :skip => [:registrations]
  root to: 'pages#home'
  resources :contacts, only: [:create]
  resources :videos do
    member do
      post 'update_rank'
    end
  end
  get 'mentions-legales', to: 'pages#legal'
  get 'realisations', to: 'videos#index'
  get 'contact', to: 'pages#contact'
  get '/admin' => redirect('/users/sign_in')
end
