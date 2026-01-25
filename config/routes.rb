Rails.application.routes.draw do
  root "calculator#index"
  post "calculate", to: "calculator#calculate"
  get "year_detail/:year", to: "calculator#year_detail", as: :year_detail
  get "methodology", to: "calculator#methodology"

  get "up" => "rails/health#show", as: :rails_health_check
end
