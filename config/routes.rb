Rails.application.routes.draw do
  get "rsvp/index", as: :rsvp
  post "rsvp/submit", to: "rsvp#submit", as: :rsvp_submit
  get "rsvp/submit_after_login", to: "rsvp#submit_after_login", as: :rsvp_submit_after_login
  get "rsvp/thanks", as: :rsvp_thanks
  root "home#index"

  get "/about", to: "home#about", as: :about
  get "/faq", to: "home#faq", as: :faq
  get "/rsvps", to: "home#rsvps", as: :rsvps

  get "up", to: "rails/health#show", as: :rails_health_check

  get "/dashboard", to: "dashboard#index", as: :dashboard

  namespace :admin do
    get "rsvp/index", as: :rsvp
    delete "rsvp/delete/:id", to: "rsvp#delete", as: :rsvp_delete

    get "/", to: "dashboard#index", as: :overview
    resources :users, only: %i[index show new edit create update destroy]
    resources :products, only: %i[index show new edit create update destroy]
    resources :orders, only: %i[index show edit update destroy]
  end

  resources :designs, only: %i[index show new create edit update] do
    collection do
      get :editor, action: :new, as: :editor
    end
  end

  get "orders/index", to: "orders#index", as: :orders_index
  get "orders/show", to: "orders#show", as: :orders_show
  get "orders/new", to: "orders#new", as: :orders_new
  get "orders/edit", to: "orders#edit", as: :orders_edit
  get "orders/delete", to: "orders#delete", as: :orders_delete

  get "/login", to: "sessions#new", as: :login
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  match "/logout", to: "sessions#destroy", via: %i[delete get], as: :logout
end
