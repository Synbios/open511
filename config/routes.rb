Rails.application.routes.draw do

  # one page route
  root "main#home"

  # user authentication routes
  get "sign_up", to: "users#sign_up_view"
  get "sign_in", to: "users#sign_in_view"
  delete "sign_out", to: "users#delete_session"

  resources :users, only: [] do
    post "create_session", on: :collection
    post "create_new", on: :collection
  end

  devise_for :users

  # routes of saved events
  resources :bookmarks, only: [:index, :create, :destroy] do
    post "check", on: :collection # check if events are already bookmarked
  end

  # routes for API
  # there are two sets of routes. The first uses remote database and the second
  # use local database. (by default the local database is used)
  resources :events, only: [:create, :index]
  resources :local_events, only: [:create, :index]

  resources :usages, only: [:index] # only show usage info


end
