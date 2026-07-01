Rails.application.routes.draw do
  root "home#index"

  # Health & static
  get "up", to: "rails/health#show", as: :rails_health_check
  get "/favicon.ico", to: redirect("/icon.png")

  # Home
  get "/about", to: "home#about", as: :about
  get "/faq", to: "home#faq", as: :faq
  get "/rsvps", to: "home#rsvps", as: :rsvps
  get "/rsvps/og-image.svg", to: "home#rsvps_og_image", as: :rsvps_og_image

  # Auth
  get "/login",  to: "sessions#new",     as: :login
  match "/logout", to: "sessions#destroy", via: %i[delete get], as: :logout
  get  "/auth/:provider/callback", to: "sessions#create"
  get  "/auth/failure",             to: "sessions#failure"

  # Dashboard
  get "/dashboard", to: "dashboard#index", as: :dashboard

  # Shop
  get "/shop", to: "shop#index", as: :shop

  # RSVP
  get  "rsvp/",               to: "rsvp#index",               as: :rsvp
  post "rsvp/submit",         to: "rsvp#submit",              as: :rsvp_submit
  get  "rsvp/submit_after_login", to: "rsvp#submit_after_login", as: :rsvp_submit_after_login
  get  "rsvp/thanks",         to: "rsvp#thanks",              as: :rsvp_thanks

  # Designs
  resources :designs, only: %i[index show new create edit update] do
    member { get :image }
  end

  # Notifications
  resources :notifications, only: %i[index] do
    member do
      get :read
    end
  end

  # Orders
  get    "orders",       to: "orders#index", as: :orders
  get    "orders/show",  to: "orders#show",  as: :orders_show
  match  "orders/new",   to: "orders#new",   via: %i[get post], as: :orders_new
  get    "orders/edit",  to: "orders#edit",  as: :orders_edit
  get    "orders/delete", to: "orders#delete", as: :orders_delete

  # Settings
  get "settings/", to: "settings#index", as: :settings

  # Admin
  namespace :admin do
    get "/", to: "dashboard#index", as: :overview

    resources :users,    only: %i[index show new edit create update destroy]
    resources :products, only: %i[index show new edit create update destroy]
    resources :orders,   only: %i[index show edit update destroy] do
      member { delete :cancel }
    end

    get    "rsvp/index",      to: "rsvp#index",  as: :rsvp
    post   "rsvp/import",     to: "rsvp#import", as: :rsvp_import
    delete "rsvp/delete/:id", to: "rsvp#delete", as: :rsvp_delete
  end
end
