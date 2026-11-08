Rails.application.routes.draw do
  root "calculator#index"
  post "calculate", to: "calculator#calculate"
  get "year_detail/:year", to: "calculator#year_detail", as: :year_detail
  get "methodology.md", to: "agents#methodology", format: false
  get "methodology", to: "calculator#methodology"

  get "llms.txt", to: "agents#llms", format: false

  namespace :api do
    namespace :v1 do
      get "backtest", to: "backtests#index"
      get "backtest/:starting_year", to: "backtests#show"
      get "data", to: "data#show"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
