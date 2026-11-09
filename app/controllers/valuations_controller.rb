class ValuationsController < ApplicationController
  def show
    expires_in 1.day, public: true
    @analysis = ValuationAnalysis.current
  end
end
