Rails.application.routes.draw do
  # devise routes for authentication
  devise_for :users

  # one page route
  root "main#home"
end
