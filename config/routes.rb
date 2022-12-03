Rails.application.routes.draw do
  # devise routes for authentication

  get "sign_up", to: "users#sign_up_view"
  get "sign_in", to: "users#sign_in_view"
  delete "sign_out", to: "users#delete_session"

  resources :users, only: [:create] do
    post "create_session", on: :collection
  end

  resources :bookmarks, only: [:index, :create, :destroy] do
    post "check", on: :collection # check if events are already bookmarked
  end

  resources :events, only: [:create, :index]
  resources :usages, only: [:index]

  # one page route
  root "main#home"
end
