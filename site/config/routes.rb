Rails.application.routes.draw do
  draw :owner_connections
  root "pages#studio"
  resources :realisations, only: %i[index show], constraints: { id: /\d+/ }
  get "studio", to: redirect("/")
  get "videos", to: redirect("/realisations")
  get "contact", to: "pages#contact"
  get "mentions-legales", to: "pages#legal", as: :mentions_legales
  get "sitemap.xml", to: "discovery#sitemap", as: :sitemap, defaults: { format: :xml }
  get "robots.txt", to: "discovery#robots"
  get "up" => "rails/health#show", as: :rails_health_check

  # The public gallery serves thumbnails, while catalogue imports attach them locally.
  match "#{ActiveStorage.routes_prefix}/*path", via: %i[post put patch delete], to: ->(_env) { [ 404, {}, [] ] }
end
