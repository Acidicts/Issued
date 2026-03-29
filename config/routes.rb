Rails.application.routes.draw do
  get "dashboard/index"
  get "/" => "home#index", as: :root
  get "/about" => "home#about", as: :about
  get "/faq" => "home#faq", as: :faq
  # rails health check
  get "up" => "rails/health#show", as: :rails_health_check

  resource :dashboard, path: "dashboard" do
    get "/", as: :dashboard, to: "dashboard#index"
  end

  get "/login", to: "sessions#new", as: :login
  get "/auth/hackclub/callback", to: "sessions#callback", as: :hackclub_callback
  match "/logout", to: "sessions#destroy", via: [:delete, :get], as: :logout
end
