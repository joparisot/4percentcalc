Rails.application.routes.draw do
  root "calculator#index"
  get "methodology", to: "calculator#methodology"

  get "up" => "rails/health#show", as: :rails_health_check
end
