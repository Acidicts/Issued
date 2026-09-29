Rails.application.routes.draw do
  get "reviews/show"
  get "reviews/update"
  get "reviews/create"
  get "ship/show"
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
  # /login is a fallback: the sign-in form posts straight at the request phase, so a page
  # normally never lands here. See ApplicationHelper#oauth_login_form.
  match "/login", to: "sessions#new", via: %i[get post], as: :login
  match "/logout", to: "sessions#destroy", via: %i[get delete], as: :logout
  # The request phase itself is handled by the OmniAuth middleware, so this route is never
  # reached; it exists so the sign-in form has a named path to post to. The OmniAuth CSRF
  # check is the real gate, and it only accepts POST.
  post "/auth/hackclub", to: proc { [ 404, { "content-type" => "text/plain" }, [ "Not found" ] ] },
                          as: :hackclub_auth
  get  "/auth/:provider/callback", to: "sessions#create"
  get  "/auth/failure",             to: "sessions#failure"

  # Dashboard
  get "/dashboard", to: "dashboard#index", as: :dashboard

  # Shop
  get "/shop", to: "shop#index", as: :shop

  # User
  resources :user, only: %i[show] do
    member do
      get "admin"
      get "reviewer"
    end
  end

  # RSVP
  get "rsvp", to: "rsvp#index", as: :rsvp
  post "rsvp/submit", to: "rsvp#submit", as: :rsvp_submit
  get "rsvp/submit_after_login", to: "rsvp#submit_after_login", as: :rsvp_submit_after_login
  get "rsvp/thanks", to: "rsvp#thanks", as: :rsvp_thanks

  # Ships

  # Ship Requests
  resources :ship_requests, only: %i[create] do
    collection do
      get :can_make_ship_request
      get :next_step
      post :resubmit
    end
  end

  # Designs
  resources :designs, only: %i[index show new create edit update] do
    member do
      get :image
      get :add_hackatime_project
      delete :remove_hackatime_project
    end
  end

  # Devlogs
  resources :devlogs, only: %i[create update edit] do
  end

  # Comments
  resources :comments, only: %i[create update edit destroy] do
    collection do
      get :comment_box
    end
  end

  # Notifications
  resources :notifications, only: %i[index] do
    member do
      patch :read
    end
  end

  # Orders
  resources :orders, only: %i[index show new create edit update destroy] do
    collection do
      delete :cancel
      post :new_step
    end
  end

  # Settings
  get "settings/", to: "settings#index", as: :settings

  # Admin
  namespace :admin do
    get "/", to: "dashboard#index", as: :overview

    resources :users,    only: %i[index show new edit create update destroy]
    resources :products, only: %i[index show new edit create update destroy] do
      collection do
        get  :new_by_printful_id
        post :import_from_printful
      end
    end
    resources :orders,   only: %i[index show edit update destroy] do
      member do
        delete :cancel
      end
    end

    get    "rsvp/index",      to: "rsvp#index",  as: :rsvp
    post   "rsvp/import",     to: "rsvp#import", as: :rsvp_import
    delete "rsvp/delete/:id", to: "rsvp#delete", as: :rsvp_delete
  end

  # Reviewer
  namespace :reviewer do
    get "/", to: "dashboard#index", as: :dashboard

    resources :ship_requests, only: %i[index show new edit update]
    resources :user, only: %i[show]
  end
end
