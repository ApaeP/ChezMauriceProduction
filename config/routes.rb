Rails.application.routes.draw do
  devise_for :users, :skip => [:registrations]
  root to: 'pages#home'
  resources :contacts, only: [:create]
  resources :videos do
    patch :reorder, on: :member
  end
  get 'mentions-legales', to: 'pages#legal'
  get 'realisations', to: 'videos#index'
  get 'contact', to: 'pages#contact'
  get '/admin' => redirect('/users/sign_in')
end
